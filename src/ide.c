/** \file
 *
 *  \brief IDE Emulation Layer for retro-style PIO interfaces.
 *
 *  \copyright Copyright 2015-2019 Alan Cox
 *
 *  \copyright Copyright 2021-2024 Ciaran Anscomb
 *
 *  \licenseblock This file is part of XRoar, a Dragon/Tandy CoCo emulator.
 *
 *  XRoar is free software; you can redistribute it and/or modify it under the
 *  terms of the GNU General Public License as published by the Free Software
 *  Foundation, either version 3 of the License, or (at your option) any later
 *  version.
 *
 *  See COPYING.GPL for redistribution conditions.
 *
 *  \endlicenseblock
 */

#include "top-config.h"

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "array.h"
#include "xalloc.h"

#include "blockdev.h"
#include "ide.h"
#include "logging.h"
#include "serialise.h"

#define IDE_IDLE        0
#define IDE_CMD         1
#define IDE_DATA_IN     2
#define IDE_DATA_OUT    3

#define DCR_NIEN        2
#define DCR_SRST        4

#define DEVH_HEAD       15
#define DEVH_DEV        16
#define DEVH_LBA        64

#define ERR_AMNF        1
#define ERR_TKNONF      2
#define ERR_ABRT        4
#define ERR_MCR         8
#define ERR_IDNF        16
#define ERR_MC          32
#define ERR_UNC         64

#define ST_ERR          1
#define ST_IDX          2
#define ST_CORR         4
#define ST_DRQ          8
#define ST_DSC          16
#define ST_DF           32
#define ST_DRDY         64
#define ST_BSY          128

#define DCL_SRST        4
#define DCL_NIEN        2

#define IDE_CMD_CALIB           0x10
#define IDE_CMD_READ            0x20
#define IDE_CMD_READ_NR         0x21
#define IDE_CMD_WRITE           0x30
#define IDE_CMD_WRITE_NR        0x31
#define IDE_CMD_VERIFY          0x40
#define IDE_CMD_VERIFY_NR       0x41
#define IDE_CMD_SEEK            0x70
#define IDE_CMD_EDD             0x90
#define IDE_CMD_INTPARAMS       0x91
#define IDE_CMD_IDENTIFY        0xEC
#define IDE_CMD_SETFEATURES     0xEF

const uint8_t ide_magic[8] = {
  '1','D','E','D','1','5','C','0'
};

/*
static char *charmap(uint8_t v)
{
  static char cbuf[3];
  if (v < 32)
    sprintf(cbuf, "^%c", '@'+v);
  else if (v < 127)
    sprintf(cbuf, " %c", v);
  else if (v == 127)
    sprintf(cbuf, "DL");
  else if (v < 160)
    sprintf(cbuf, ":%c", '@' + v - 128);
  else if (v < 255)
    sprintf(cbuf, "~%c", v - 128);
  else
    sprintf(cbuf, "!D");
  return cbuf;
}

static void hexdump(uint8_t *bp)
{
  int i,j;
  for (i = 0; i < 512; i+= 16) {
    for(j = 0; j < 16; j++)
      fprintf(stderr, "%02X ", bp[i+j]);
    fprintf(stderr, "|");
    for(j = 0; j < 16; j++)
      fprintf(stderr, "%2s", charmap(bp[i+j]));
    fprintf(stderr, "\n");
  }
}
*/

static uint16_t le16(uint16_t v)
{
  uint8_t *p = (uint8_t *)&v;
  return p[0] | (p[1] << 8);
}

static void ide_xlate_errno(struct ide_taskfile *t)
{
  // This function used to differentiate between EIO ("correctable") and other
  // errors.  Now that block device access is abstracted, we can only report
  // uncorrectable errors.
  t->status |= ST_ERR;
  t->error = ERR_AMNF;
}

static void ide_fault(struct ide_drive *d, const char *p)
{
  LOG_MOD_WARN("idedisk", "%s: %d: %s\n", d->controller->name,
               (int)(d - d->controller->drive), p);
}

/* Disk translation */
static off_t xlate_block(struct ide_taskfile *t)
{
  struct ide_drive *d = t->drive;
  uint16_t cyl;

  if (t->lba4 & DEVH_LBA) {
/*    fprintf(stderr, "XLATE LBA %02X:%02X:%02X:%02X\n",
      t->lba4, t->lba3, t->lba2, t->lba1);*/
    if (d->lba)
      return (((t->lba4 & DEVH_HEAD) << 24) | (t->lba3 << 16) | (t->lba2 << 8) | t->lba1);
    ide_fault(d, "LBA on non LBA drive");
  }

  /* Some well known software asks for 0/0/0 when it means 0/0/1. Drives appear
     to interpret sector 0 as sector 1 */
  if (t->lba1 == 0) {
    LOG_MOD_DEBUG(2, "idedisk", "[Bug: request for sector offset 0].\n");
    t->lba1 = 1;
  }
  cyl = (t->lba3 << 8) | t->lba2;
  /* fprintf(stderr, "(H %d C %d S %d)\n", t->lba4 & DEVH_HEAD, cyl, t->lba1); */
  if (t->lba1 == 0 || t->lba1 > d->sectors || t->lba4 >= d->heads || cyl >= d->cylinders) {
    return -1;
  }
  /* Sector 1 is first */
  /* Images generally go cylinder/head/sector. This also matters if we ever
     implement more advanced geometry setting */
  return (((cyl * d->heads) + (t->lba4 & DEVH_HEAD)) * d->sectors + t->lba1) - 1;
}

/* Indicate the drive is ready */
static void ready(struct ide_taskfile *tf)
{
  tf->status &= ~(ST_BSY|ST_DRQ);
  tf->status |= ST_DRDY;
  tf->drive->state = IDE_IDLE;
}

/* Return to idle state, completing a command */
static void completed(struct ide_taskfile *tf)
{
  ready(tf);
  tf->drive->intrq = 1;
}

static void drive_failed(struct ide_taskfile *tf)
{
  tf->status |= ST_ERR;
  tf->error = ERR_IDNF;
  ready(tf);
}

static void data_in_state(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  d->state = IDE_DATA_IN;
  d->dptr = d->data + 512;
  /* We don't clear DRDY here, drives may well accept a command at this
     point and at least one firmware for RC2014 assumes this */
  tf->status &= ~ST_BSY;
  tf->status |= ST_DRQ;
  d->intrq = 1;                 /* Double check */
}

static void data_out_state(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  d->state = IDE_DATA_OUT;
  d->dptr = d->data;
  tf->status &= ~ (ST_BSY|ST_DRDY);
  tf->status |= ST_DRQ;
  d->intrq = 1;                 /* Double check */
}

static void edd_setup(struct ide_taskfile *tf)
{
  tf->error = 0x01;             /* All good */
  tf->lba1 = 0x01;              /* EDD always updates drive 0 */
  tf->lba2 = 0x00;
  tf->lba3 = 0x00;
  tf->lba4 = 0x00;
  tf->count = 0x01;
  ready(tf);
}

void ide_reset_drive(struct ide_drive *d)
{
  if (d->present) {
    edd_setup(&d->taskfile);
    /* A drive could clear busy then set DRDY up to 2 minutes later if its
       mindnumbingly slow to start up ! We don't emulate any of that */
    d->taskfile.status = ST_DRDY;
    d->eightbit = 0;
  }
}

static void ide_reset(struct ide_controller *c)
{
  ide_reset_drive(&c->drive[0]);
  ide_reset_drive(&c->drive[1]);
  c->selected = 0;
}

void ide_reset_begin(struct ide_controller *c)
{
  if (c->drive[0].present)
    c->drive[0].taskfile.status |= ST_BSY;
  if (c->drive[1].present)
    c->drive[1].taskfile.status |= ST_BSY;
  /* Ought to be a time delay relative to reset or power on */
  ide_reset(c);
}

static void ide_srst_begin(struct ide_controller *c)
{
  ide_reset(c);
  if (c->drive[0].present)
    c->drive[0].taskfile.status |= ST_BSY;
  if (c->drive[1].present)
    c->drive[1].taskfile.status |= ST_BSY;
}

static void ide_srst_end(struct ide_controller *c)
{
  /* Could be time delays here */
  ready(&c->drive[0].taskfile);
  ready(&c->drive[1].taskfile);
}

static void cmd_edd_complete(struct ide_taskfile *tf)
{
  struct ide_controller *c = tf->drive->controller;
  if (c->drive[0].present)
    edd_setup(&c->drive[0].taskfile);
  if (c->drive[1].present)
    edd_setup(&c->drive[1].taskfile);
  c->selected = 0;
}

static void cmd_identify_complete(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  memcpy(d->data, d->identify, 512);
  data_in_state(tf);
  /* Arrange to copy just the identify buffer */
  d->dptr = d->data;
  d->length = 1;
}

static void cmd_initparam_complete(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  /* We only support the current mapping */
  if (tf->count != d->sectors || (tf->lba4 & DEVH_HEAD) + 1 != d->heads) {
    tf->status |= ST_ERR;
    tf->error |= ERR_ABRT;
    tf->drive->failed = 1;              /* Report ID NF until fixed */
/*    fprintf(stderr, "geo is %d %d, asked for %d %d\n",
      d->sectors, d->heads, tf->count, (tf->lba4 & DEVH_HEAD) + 1); */
    ide_fault(d, "invalid geometry");
  } else if (tf->drive->failed == 1)
    tf->drive->failed = 0;              /* Valid translation */
  completed(tf);
}

static void cmd_readsectors_complete(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  /* Move to data xfer */
  if (d->failed) {
    drive_failed(tf);
    return;
  }
  d->offset = xlate_block(tf);
  /* DRDY is not guaranteed here but at least one buggy RC2014 firmware
     expects it */
  tf->status |= ST_DRQ | ST_DSC | ST_DRDY;
  tf->status &= ~ST_BSY;
  /* 0 = 256 sectors */
  d->length = tf->count ? tf->count : 256;
/*  fprintf(stderr, "READ %d SECTORS @ %ld\n", d->length, d->offset); */
  if (d->offset == -1 || !bd_seek_lsn(d->bd, d->offset)) {
    tf->status |= ST_ERR;
    tf->status &= ~ST_DSC;
    tf->error |= ERR_IDNF;
    /* return null data */
    completed(tf);
    return;
  }
  /* do the xfer */
  data_in_state(tf);
}

static void cmd_verifysectors_complete(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  /* Move to data xfer */
  if (d->failed) {
    drive_failed(tf);
    return;
  }
  d->offset = xlate_block(tf);
  /* 0 = 256 sectors */
  d->length = tf->count ? tf->count : 256;
  if (d->offset == -1 || !bd_read_lsn(d->bd, d->offset + d->length - 1, NULL, 0)) {
    tf->status &= ~ST_DSC;
    tf->status |= ST_ERR;
    tf->error |= ERR_IDNF;
  }
  tf->status |= ST_DSC;
  completed(tf);
}

static void cmd_recalibrate_complete(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  if (d->failed)
    drive_failed(tf);
  if (d->offset == -1 || xlate_block(tf) != 0L) {
    tf->status &= ~ST_DSC;
    tf->status |= ST_ERR;
    tf->error |= ERR_ABRT;
  }
  tf->status |= ST_DSC;
  completed(tf);
}

static void cmd_seek_complete(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  if (d->failed)
    drive_failed(tf);
  d->offset = xlate_block(tf);
  if (d->offset == -1 || !bd_seek_lsn(d->bd, d->offset)) {
    tf->status &= ~ST_DSC;
    tf->status |= ST_ERR;
    tf->error |= ERR_IDNF;
  }
  tf->status |= ST_DSC;
  completed(tf);
}

static void cmd_setfeatures_complete(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  switch(tf->feature) {
    case 0x01:
      d->eightbit = 1;
      break;
    case 0x03:
      if ((tf->count & 0xF0) >= 0x20) {
        tf->status |= ST_ERR;
        tf->error |= ERR_ABRT;
      }
      /* Silently accept PIO mode settings */
      break;
    case 0x81:
      d->eightbit = 0;
      break;
    default:
      tf->status |= ST_ERR;
      tf->error |= ERR_ABRT;
  }
  completed(tf);
}

static void cmd_writesectors_complete(struct ide_taskfile *tf)
{
  struct ide_drive *d = tf->drive;
  /* Move to data xfer */
  if (d->failed) {
    drive_failed(tf);
    return;
  }
  d->offset = xlate_block(tf);
  tf->status |= ST_DRQ;
  /* 0 = 256 sectors */
  d->length = tf->count ? tf->count : 256;
/*  fprintf(stderr, "WRITE %d SECTORS @ %ld\n", d->length, d->offset); */
  if (d->offset == -1 || !bd_seek_lsn(d->bd, d->offset)) {
    tf->status |= ST_ERR;
    tf->error |= ERR_IDNF;
    tf->status &= ~ST_DSC;
    /* return null data */
    completed(tf);
    return;
  }
  /* do the xfer */
  data_out_state(tf);
}

static void ide_set_error(struct ide_drive *d)
{
  d->taskfile.lba4 &= ~DEVH_HEAD;

  if (d->taskfile.lba4 & DEVH_LBA) {
    d->taskfile.lba1 = d->offset & 0xFF;
    d->taskfile.lba2 = (d->offset >> 8) & 0xFF;
    d->taskfile.lba3 = (d->offset >> 16) & 0xFF;
    d->taskfile.lba4 |= (d->offset >> 24) & DEVH_HEAD;
  } else {
    d->taskfile.lba1 = d->offset % d->sectors + 1;
    d->offset /= d->sectors;
    d->taskfile.lba4 |= d->offset / (d->cylinders * d->sectors);
    d->offset %= (d->cylinders * d->sectors);
    d->taskfile.lba2 = d->offset & 0xFF;
    d->taskfile.lba3 = (d->offset >> 8) & 0xFF;
  }
  d->taskfile.count = d->length;
  d->taskfile.status |= ST_ERR;
  d->state = IDE_IDLE;
  completed(&d->taskfile);
}

static int ide_read_sector(struct ide_drive *d)
{
  d->dptr = d->data;
  if (!bd_read(d->bd, d->data, 512)) {
    perror("ide_read_sector");
    d->taskfile.status |= ST_ERR;
    d->taskfile.status &= ~ST_DSC;
    ide_xlate_errno(&d->taskfile);
    return -1;
  }
//  hexdump(d->data);
  d->offset += 512;
  return 0;
}

static int ide_write_sector(struct ide_drive *d)
{
  d->dptr = d->data;
  if (!bd_write(d->bd, d->data, 512)) {
    d->taskfile.status |= ST_ERR;
    d->taskfile.status &= ~ST_DSC;
    ide_xlate_errno(&d->taskfile);
    return -1;
  }
//  hexdump(d->data);
  d->offset += 512;
  return 0;
}

static uint16_t ide_data_in(struct ide_drive *d, int len)
{
  if (d->state == IDE_DATA_IN) {
    if (d->dptr == d->data + 512) {
      if (ide_read_sector(d) < 0) {
        ide_set_error(d);       /* Set the LBA or CHS etc */
        return 0xFFFF;          /* and error bits set by read_sector */
      }
    }
    uint16_t v = *d->dptr;
    if (!d->eightbit) {
      if (len == 2)
        v |= (d->dptr[1] << 8);
      d->dptr+=2;
    } else
      d->dptr++;
    d->taskfile.data = v;
    if (d->dptr == d->data + 512) {
      d->length--;
      d->intrq = 1;             /* we don't yet emulate multimode */
      if (d->length == 0) {
        d->state = IDE_IDLE;
        completed(&d->taskfile);
      }
    }
  } else
    ide_fault(d, "bad data read");

  if (len == 1)
    return d->taskfile.data & 0xFF;
  return d->taskfile.data;
}

static void ide_data_out(struct ide_drive *d, uint16_t v)
{
  if (d->state != IDE_DATA_OUT) {
    ide_fault(d, "bad data write");
    d->taskfile.data = v;
  } else {
    if (d->eightbit)
      v &= 0xFF;
    *d->dptr++ = v;
    d->taskfile.data = v;
    if (!d->eightbit) {
      *d->dptr++ = v >> 8;
      d->taskfile.data = v >> 8;
    }
    if (d->dptr == d->data + 512) {
      if (ide_write_sector(d) < 0) {
        ide_set_error(d);
        return;
      }
      d->length--;
      d->intrq = 1;
      if (d->length == 0) {
        d->state = IDE_IDLE;
        d->taskfile.status |= ST_DSC;
        completed(&d->taskfile);
      }
    }
  }
}

static void ide_issue_command(struct ide_taskfile *t)
{
  t->status &= ~(ST_ERR|ST_DRDY);
  t->status |= ST_BSY;
  t->error = 0;
  t->drive->state = IDE_CMD;

  /* We could complete with delays but don't do so yet */
  switch(t->command) {
    case IDE_CMD_EDD:   /* 0x90 */
      cmd_edd_complete(t);
      break;
    case IDE_CMD_IDENTIFY:      /* 0xEC */
      cmd_identify_complete(t);
      break;
    case IDE_CMD_INTPARAMS:     /* 0x91 */
      cmd_initparam_complete(t);
      break;
    case IDE_CMD_READ:          /* 0x20 */
    case IDE_CMD_READ_NR:       /* 0x21 */
      cmd_readsectors_complete(t);
      break;
    case IDE_CMD_SETFEATURES:   /* 0xEF */
      cmd_setfeatures_complete(t);
      break;
    case IDE_CMD_VERIFY:        /* 0x40 */
    case IDE_CMD_VERIFY_NR:     /* 0x41 */
      cmd_verifysectors_complete(t);
      break;
    case IDE_CMD_WRITE:         /* 0x30 */
    case IDE_CMD_WRITE_NR:      /* 0x31 */
      cmd_writesectors_complete(t);
      break;
    default:
      if ((t->command & 0xF0) == IDE_CMD_CALIB) /* 1x */
        cmd_recalibrate_complete(t);
      else if ((t->command & 0xF0) == IDE_CMD_SEEK) /* 7x */
        cmd_seek_complete(t);
      else {
        /* Unknown */
        t->status |= ST_ERR;
        t->error |= ERR_ABRT;
        completed(t);
      }
  }
}

/*
 *      8bit IDE controller emulation
 */

uint8_t ide_read8(struct ide_controller *c, uint8_t r)
{
  struct ide_drive *d = &c->drive[c->selected];
  struct ide_taskfile *t = &d->taskfile;
  switch(r) {
    case ide_data:
      return ide_data_in(d, 1);
    case ide_error_r:
      return t->error;
    case ide_sec_count:
      return t->count;
    case ide_lba_low:
      return t->lba1;
    case ide_lba_mid:
      return t->lba2;
    case ide_lba_hi:
      return t->lba3;
    case ide_lba_top:
      return t->lba4;
    case ide_status_r:
      d->intrq = 0;             /* Acked */
      // fall through
    case ide_altst_r:
      return t->status;
    default:
      ide_fault(d, "bogus register");
      return 0xFF;
  }
}

void ide_write8(struct ide_controller *c, uint8_t r, uint8_t v)
{
  struct ide_drive *d = &c->drive[c->selected];
  struct ide_taskfile *t = &d->taskfile;

  if (r != ide_devctrl_w) {
    if (t->status & ST_BSY) {
      ide_fault(d, "command written while busy");
      return;
    }
    /* Not clear this is the right emulation */
    if (d->present == 0 && r != ide_lba_top) {
      ide_fault(d, "not present");
      return;
    }
  }

  switch(r) {
    case ide_data:
      ide_data_out(d, v);
      break;
    case ide_feature_w:
      t->feature = v;
      break;
    case ide_sec_count:
      t->count = v;
      break;
    case ide_lba_low:
      t->lba1 = v;
      break;
    case ide_lba_mid:
      t->lba2 = v;
      break;
    case ide_lba_hi:
      t->lba3 = v;
      break;
    case ide_lba_top:
      c->selected = (v & DEVH_DEV) ? 1 : 0;
      c->drive[c->selected].taskfile.lba4 = v & (DEVH_HEAD|DEVH_DEV|DEVH_LBA);
      break;
    case ide_command_w:
      t->command = v;
      ide_issue_command(t);
      break;
    case ide_devctrl_w:
      /* ATA: "When the Device Control register is written, both devices
         respond to the write regardless of which device is selected" */
      if ((v ^ t->devctrl) & DCL_SRST) {
        if (v & DCL_SRST)
          ide_srst_begin(c);
        else
          ide_srst_end(c);
      }
      c->drive[0].taskfile.devctrl = v;	/* Check versus real h/w does this end up cleared */
      c->drive[1].taskfile.devctrl = v;
      break;
  }
}

/*
 *      16bit IDE controller emulation
 */

uint16_t ide_read16(struct ide_controller *c, uint8_t r)
{
  struct ide_drive *d = &c->drive[c->selected];
  if (r == ide_data)
    return ide_data_in(d,2);
  return ide_read8(c, r);
}

void ide_write16(struct ide_controller *c, uint8_t r, uint16_t v)
{
  struct ide_drive *d = &c->drive[c->selected];
  struct ide_taskfile *t = &d->taskfile;

  if (r != ide_devctrl_w && (t->status & ST_BSY)) {
    ide_fault(d, "command written while busy");
    return;
  }
  if (r == ide_data)
    ide_data_out(d, v);
  else
    ide_write8(c, r, v);
}

/*
 *      Allocate a new IDE controller emulation
 */
struct ide_controller *ide_allocate(const char *name)
{
  struct ide_controller *c = calloc(1, sizeof(*c));
  if (c == NULL)
    return NULL;
  c->name = xstrdup(name);
  if (c->name == NULL) {
    free(c);
    return NULL;
  }
  c->drive[0].controller = c;
  c->drive[1].controller = c;
  c->drive[0].taskfile.drive = &c->drive[0];
  c->drive[1].taskfile.drive = &c->drive[1];
  return c;
}

/*
 *      Attach a file to a device on the controller
 */
int ide_attach(struct ide_controller *c, int drive, struct blkdev *bd)
{
  struct ide_drive *d = &c->drive[drive];
  if (d->present) {
    ide_fault(d, "double attach");
    return -1;
  }
  if (!bd_ide_read_identify(bd, d->identify, 512)) {
    ide_fault(d, "failed to read identify");
    return -1;
  }
  d->bd = bd;
  d->present = 1;
  d->heads = le16(d->identify[3]);
  d->sectors = le16(d->identify[6]);
  d->cylinders = le16(d->identify[1]);
  if (d->identify[49] & le16(1 << 9))
    d->lba = 1;
  else
    d->lba = 0;
  return 0;
}

/*
 *      Detach an IDE device from the interface (not hot pluggable)
 */
void ide_detach(struct ide_drive *d)
{
  bd_close(d->bd);
  d->bd = NULL;
  d->present = 0;
}

/*
 *      Free up and release and IDE controller
 */
void ide_free(struct ide_controller *c)
{
  if (c->drive[0].present)
    ide_detach(&c->drive[0]);
  if (c->drive[1].present)
    ide_detach(&c->drive[1]);
  free((void *)c->name);
  free(c);
}

/*
 *      Emulation interface for an 8bit controller using latches on the
 *      data register
 */
uint8_t ide_read_latched(struct ide_controller *c, uint8_t reg)
{
  uint16_t v;
  if (reg == ide_data_latch)
    return c->data_latch;
  v = ide_read16(c, reg);
  if (reg == ide_data) {
    c->data_latch = v >> 8;
    v &= 0xFF;
  }
  return v;
}

void ide_write_latched(struct ide_controller *c, uint8_t reg, uint8_t v)
{
  uint16_t d = v;

  if (reg == ide_data_latch) {
    c->data_latch = v;
    return;
  }
  if (reg == ide_data)
    d |=  (c->data_latch << 8);
  ide_write16(c, reg, d);
}

// If there's a bug in this now, it's mine, not Alan's ..ciaran
static void make_ascii(uint16_t *p, const char *t, int len)
{
  char *d = (char *)p;
  for (int i = 0; i < len; i += 2) {
    char c1 = t ? *t : 0;
    t = c1 ? t : NULL;
    char c0 = t ? *(t+1) : 0;
    t = c0 ? t + 2 : NULL;
    *(d++) = c0;
    *(d++) = c1;
  }
}

static void make_serial(uint16_t *p)
{
  char buf[21];
  // assume srand() called at startup
  snprintf(buf, 21, "%08d%08d%04d", rand(), rand(), rand());
  make_ascii(p, buf, 20);
}

int ide_make_drive(uint8_t type, int fd)
{
  uint8_t s, h;
  uint16_t c;
  uint32_t sectors;
  uint16_t ident[256];

  if (type < 1 || type > MAX_DRIVE_TYPE)
    return -2;

  memset(ident, 0, 512);
  memcpy(ident, ide_magic, 8);
  if (write(fd, ident, 512) != 512)
    return -1;

  memset(ident, 0, 8);
  ident[0] = le16((1 << 15) | (1 << 6));        /* Non removable */
  make_serial(ident + 10);
  ident[47] = 0; /* no read multi for now */
  ident[51] = le16(240 /* PIO2 */ << 8);        /* PIO cycle time */
  ident[53] = le16(1);          /* Geometry words are valid */

  switch(type) {
    case BD_ACME_ROADRUNNER:
      /* 504MB drive with LBA support */
      c = 1024;
      h = 16;
      s = 63;
      make_ascii(ident + 23, "A001.001", 8);
      make_ascii(ident + 27, "ACME ROADRUNNER v0.1", 40);
      ident[49] = le16(1 << 9); /* LBA */
      break;
    case BD_ACME_ULTRASONICUS:
      /* 40MB drive with LBA support */
      c = 977;
      h = 5;
      s = 16;
      ident[49] = le16(1 << 9); /* LBA */
      make_ascii(ident + 23, "A001.001", 8);
      make_ascii(ident + 27, "ACME ULTRASONICUS AD INFINITUM v0.1", 40);
      break;
    case BD_ACME_NEMESIS:
      /* 20MB drive with LBA support */
      c = 615;
      h = 4;
      s = 16;
      ident[49] = le16(1 << 9); /* LBA */
      make_ascii(ident + 23, "A001.001", 8);
      make_ascii(ident + 27, "ACME NEMESIS RIDICULII v0.1", 40);
      break;
    case BD_ACME_COYOTE:
      /* 20MB drive without LBA support */
      c = 615;
      h = 4;
      s = 16;
      make_ascii(ident + 23, "A001.001", 8);
      make_ascii(ident + 27, "ACME COYOTE v0.1", 40);
      break;
    case BD_ACME_ACCELLERATTI:
      c = 1024;
      h = 16;
      s = 16;
      ident[49] = le16(1 << 9); /* LBA */
      make_ascii(ident + 23, "A001.001", 8);
      make_ascii(ident + 27, "ACME ACCELLERATTI INCREDIBILUS v0.1", 40);
      break;
    case BD_ACME_ZIPPIBUS:
      c = 1024;
      h = 16;
      s = 32;
      ident[49] = le16(1 << 9); /* LBA */
      make_ascii(ident + 23, "A001.001", 8);
      make_ascii(ident + 27, "ACME ZIPPIBUS v0.1", 40);
      break;
    default:
      return -2;
  }

  ident[1] = le16(c);
  ident[3] = le16(h);
  ident[6] = le16(s);
  ident[54] = ident[1];
  ident[55] = ident[3];
  ident[56] = ident[6];
  sectors = c * h * s;
  ident[57] = le16(sectors & 0xFFFF);
  ident[58] = le16(sectors >> 16);
  ident[60] = ident[57];
  ident[61] = ident[58];
  if (write(fd, ident, 512) != 512)
    return -1;

  memset(ident, 0xE5, 512);
  while(sectors--)
    if (write(fd, ident, 512) != 512)
      return -1;
  return 0;
}

// Most of this file is as contributed (as it's had at least one update, and
// switching code styles would make merging that difficult!), but serialisation
// code is a necessary inclusion here:

#define IDE_DRIVE_SER_DATA   (15)
#define IDE_DRIVE_SER_DPTR   (16)
#define IDE_DRIVE_SER_OFFSET (18)

static const struct ser_struct ser_struct_ide_drive[] = {
	SER_ID_STRUCT_ELEM(1, struct ide_drive, taskfile.data),
	SER_ID_STRUCT_ELEM(2, struct ide_drive, taskfile.error),
	SER_ID_STRUCT_ELEM(3, struct ide_drive, taskfile.feature),
	SER_ID_STRUCT_ELEM(4, struct ide_drive, taskfile.count),
	SER_ID_STRUCT_ELEM(5, struct ide_drive, taskfile.lba1),
	SER_ID_STRUCT_ELEM(6, struct ide_drive, taskfile.lba2),
	SER_ID_STRUCT_ELEM(7, struct ide_drive, taskfile.lba3),
	SER_ID_STRUCT_ELEM(8, struct ide_drive, taskfile.lba4),
	SER_ID_STRUCT_ELEM(9, struct ide_drive, taskfile.status),
	SER_ID_STRUCT_ELEM(10, struct ide_drive, taskfile.command),
	SER_ID_STRUCT_ELEM(11, struct ide_drive, taskfile.devctrl),
	SER_ID_STRUCT_ELEM(12, struct ide_drive, intrq),
	SER_ID_STRUCT_ELEM(13, struct ide_drive, failed),
	SER_ID_STRUCT_ELEM(14, struct ide_drive, eightbit),
	SER_ID_STRUCT_UNHANDLED(IDE_DRIVE_SER_DATA),
	SER_ID_STRUCT_UNHANDLED(IDE_DRIVE_SER_DPTR),
	SER_ID_STRUCT_ELEM(17, struct ide_drive, state),
	SER_ID_STRUCT_UNHANDLED(IDE_DRIVE_SER_OFFSET),
	SER_ID_STRUCT_ELEM(19, struct ide_drive, length),
};

static _Bool ide_drive_read_elem(void *sptr, struct ser_handle *sh, int tag);
static _Bool ide_drive_write_elem(void *sptr, struct ser_handle *sh, int tag);

static const struct ser_struct_data ide_drive_ser_struct_data = {
	.elems = ser_struct_ide_drive,
	.num_elems = ARRAY_N_ELEMENTS(ser_struct_ide_drive),
	.read_elem = ide_drive_read_elem,
	.write_elem = ide_drive_write_elem,
};

#define IDE_CONTROLLER_SER_DRIVE (1)

static const struct ser_struct ser_struct_ide_controller[] = {
	SER_ID_STRUCT_UNHANDLED(IDE_CONTROLLER_SER_DRIVE),
	SER_ID_STRUCT_ELEM(2, struct ide_controller, selected),
	SER_ID_STRUCT_ELEM(3, struct ide_controller, data_latch),
};

static _Bool ide_controller_read_elem(void *sptr, struct ser_handle *sh, int tag);
static _Bool ide_controller_write_elem(void *sptr, struct ser_handle *sh, int tag);

static const struct ser_struct_data ide_controller_ser_struct_data = {
	.elems = ser_struct_ide_controller,
	.num_elems = ARRAY_N_ELEMENTS(ser_struct_ide_controller),
	.read_elem = ide_controller_read_elem,
	.write_elem = ide_controller_write_elem,
};

static _Bool ide_drive_read_elem(void *sptr, struct ser_handle *sh, int tag) {
	struct ide_drive *ided = sptr;
	switch (tag) {
	case IDE_DRIVE_SER_DATA:
		ser_read(sh, ided->data, sizeof(ided->data));
		break;
	case IDE_DRIVE_SER_DPTR:
		ided->dptr = ided->data + ser_read_vuint32(sh);
		break;
	case IDE_DRIVE_SER_OFFSET:
		ided->offset = ser_read_vuint32(sh);
		break;
	default:
		ser_set_error(sh, ser_error_format);
		return 0;
	}
	return 1;
}

static _Bool ide_drive_write_elem(void *sptr, struct ser_handle *sh, int tag) {
	struct ide_drive *ided = sptr;
	switch (tag) {
	case IDE_DRIVE_SER_DATA:
		ser_write(sh, tag, ided->data, sizeof(ided->data));
		break;
	case IDE_DRIVE_SER_DPTR:
		ser_write_vuint32(sh, tag, ided->dptr - ided->data);
		break;
	case IDE_DRIVE_SER_OFFSET:
		ser_write_vuint32(sh, tag, ided->offset);
		break;
	default:
		ser_set_error(sh, ser_error_format);
		return 0;
	}
	return 1;
}

static _Bool ide_controller_read_elem(void *sptr, struct ser_handle *sh, int tag) {
	struct ide_controller *ide = sptr;
	switch (tag) {
	case IDE_CONTROLLER_SER_DRIVE:
		{
			unsigned i = ser_read_vuint32(sh);
			if (i >= 2) {
				return 0;
			}
			ser_read_struct_data(sh, &ide_drive_ser_struct_data, &ide->drive[i]);
		}
		break;
	default:
		return 0;
	}
	return 1;
}

static _Bool ide_controller_write_elem(void *sptr, struct ser_handle *sh, int tag) {
	struct ide_controller *ide = sptr;
	switch (tag) {
	case IDE_CONTROLLER_SER_DRIVE:
		for (unsigned i = 0; i < 2; i++) {
			ser_write_open_vuint32(sh, tag, i);
			ser_write_struct_data(sh, &ide_drive_ser_struct_data, &ide->drive[i]);
		}
		break;
	default:
		return 0;
	}
	return 1;
}

void ide_deserialise(struct ide_controller *ide, struct ser_handle *sh) {
	ser_read_struct_data(sh, &ide_controller_ser_struct_data, ide);
}

void ide_serialise(struct ide_controller *ide, struct ser_handle *sh, unsigned otag) {
	ser_write_open_string(sh, otag, ide->name);
	ser_write_struct_data(sh, &ide_controller_ser_struct_data, ide);
}
