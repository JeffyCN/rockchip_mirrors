/* GStreamer
 * Copyright (C) <2022> Collabora Ltd.
 *   Author: Julian Bouzas <julian.bouzas@collabora.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <gst/pbutils/pbutils.h>

#include "gstmppjpegdecodebin.h"

GST_DEBUG_CATEGORY_STATIC (mppjpegdecodebin_debug);
#define GST_CAT_DEFAULT (mppjpegdecodebin_debug)

struct _GstMppJpegDecodeBin
{
  GstBin parent;

  gboolean constructed;
  const gchar *missing_element;
};

#define gst_mpp_jpeg_decode_bin_parent_class parent_class
G_DEFINE_TYPE (GstMppJpegDecodeBin, gst_mpp_jpeg_decode_bin, GST_TYPE_BIN);

static GstStaticPadTemplate gst_mpp_jpeg_decode_bin_sink_template =
GST_STATIC_PAD_TEMPLATE ("sink",
    GST_PAD_SINK,
    GST_PAD_ALWAYS,
    GST_STATIC_CAPS ("image/jpeg")
    );

static GstStaticPadTemplate gst_mpp_jpeg_decode_bin_src_template =
GST_STATIC_PAD_TEMPLATE ("src",
    GST_PAD_SRC,
    GST_PAD_ALWAYS,
    GST_STATIC_CAPS ("ANY")
    );

static gboolean
gst_mpp_jpeg_decode_bin_open (GstMppJpegDecodeBin * self)
{
  if (self->missing_element) {
    gst_element_post_message (GST_ELEMENT (self),
        gst_missing_element_message_new (GST_ELEMENT (self),
            self->missing_element));
  } else if (!self->constructed) {
    GST_ELEMENT_ERROR (self, CORE, FAILED,
        ("Failed to construct mpp jpeg decoder pipeline."), (NULL));
  }

  return self->constructed;
}

static GstStateChangeReturn
gst_mpp_jpeg_decode_bin_change_state (GstElement * element,
    GstStateChange transition)
{
  GstMppJpegDecodeBin *self = GST_MPP_JPEG_DECODE_BIN (element);

  switch (transition) {
    case GST_STATE_CHANGE_NULL_TO_READY:
      if (!gst_mpp_jpeg_decode_bin_open (self))
        return GST_STATE_CHANGE_FAILURE;
      break;
    default:
      break;
  }

  return GST_ELEMENT_CLASS (parent_class)->change_state (element, transition);
}

static void
gst_mpp_jpeg_decode_bin_constructed (GObject * obj)
{
  GstMppJpegDecodeBin *self = GST_MPP_JPEG_DECODE_BIN (obj);
  GstElementClass *klass = GST_ELEMENT_GET_CLASS (GST_ELEMENT (self));
  GstPad *src_gpad, *sink_gpad;
  GstPad *src_pad = NULL, *sink_pad = NULL;
  GstElement *jpegparse = NULL;
  GstElement *mppjpegdec = NULL;

  /* setup ghost pads */
  sink_gpad = gst_ghost_pad_new_no_target_from_template ("sink",
      gst_element_class_get_pad_template (klass, "sink"));
  gst_element_add_pad (GST_ELEMENT (self), sink_gpad);

  src_gpad = gst_ghost_pad_new_no_target_from_template ("src",
      gst_element_class_get_pad_template (klass, "src"));
  gst_element_add_pad (GST_ELEMENT (self), src_gpad);

  /* create elements */
  jpegparse = gst_element_factory_make ("jpegparse", NULL);
  if (!jpegparse) {
    self->missing_element = "jpegparse";
    goto cleanup;
  }

  mppjpegdec = gst_element_factory_make ("mppjpegdec", NULL);
  if (!mppjpegdec) {
    self->missing_element = "mppjpegdec";
    goto cleanup;
  }

  gst_bin_add_many (GST_BIN (self), jpegparse, mppjpegdec, NULL);

  /* link elements */
  sink_pad = gst_element_get_static_pad (jpegparse, "sink");
  gst_ghost_pad_set_target (GST_GHOST_PAD (sink_gpad), sink_pad);
  gst_object_unref (sink_pad);

  gst_element_link_pads (jpegparse, "src", mppjpegdec, "sink");

  src_pad = gst_element_get_static_pad (mppjpegdec, "src");
  gst_ghost_pad_set_target (GST_GHOST_PAD (src_gpad), src_pad);
  gst_object_unref (src_pad);

  /* signal success, we will handle this in NULL->READY transition */
  self->constructed = TRUE;
  return;

cleanup:
  if (jpegparse)
    gst_object_unref (jpegparse);
  if (mppjpegdec)
    gst_object_unref (mppjpegdec);

  G_OBJECT_CLASS (parent_class)->constructed (obj);
}

static void
gst_mpp_jpeg_decode_bin_class_init (GstMppJpegDecodeBinClass * klass)
{
  GstElementClass *element_class = (GstElementClass *) klass;
  GObjectClass *obj_class = (GObjectClass *) klass;

  obj_class->constructed = gst_mpp_jpeg_decode_bin_constructed;

  gst_element_class_add_static_pad_template (element_class,
      &gst_mpp_jpeg_decode_bin_src_template);
  gst_element_class_add_static_pad_template (element_class,
      &gst_mpp_jpeg_decode_bin_sink_template);
  element_class->change_state =
      GST_DEBUG_FUNCPTR (gst_mpp_jpeg_decode_bin_change_state);

  gst_element_class_set_static_metadata (element_class,
      "Rockchip's MPP JPEG Decode Bin", "Codec/Decoder/Video",
      "Wrapper JPEG decoder to decode unparsed JPEG buffers",
      "Julian Bouzas <julian.bouzas@collabora.com>");
}

static void
gst_mpp_jpeg_decode_bin_init (GstMppJpegDecodeBin * self)
{
  (void) self;
}

gboolean
gst_mpp_jpeg_decode_bin_register (GstPlugin * plugin, guint rank)
{
  return gst_element_register (plugin, "mppjpegdecodebin", rank,
      gst_mpp_jpeg_decode_bin_get_type ());
}
