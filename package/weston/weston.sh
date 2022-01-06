# The env variables below can be override by the init script(e.g. S50launcher)

export XDG_RUNTIME_DIR=/var/run

# Comment out this for atomic related functions, e.g. sprites
export WESTON_DISABLE_ATOMIC=1

# Allow using drm modifier, e.g. ARM AFBC
# export WESTON_ALLOW_GBM_MODIFIERS=1

# Enable black background for fullscreen views
# export WESTON_FULLSCREEN_BLACK_BACKGROUND=1

# Primary screen
# export WESTON_DRM_PRIMARY=eDP-1

# Disable internal screens when any external screen connected
# export WESTON_DRM_PREFER_EXTERNAL=1

# Prefer using external screen as primary screen
# export WESTON_DRM_PREFER_EXTERNAL_DUAL=1

# Virtual display size
# export WESTON_DRM_VIRTUAL_SIZE=1024x768

# Comment out these to disable mirror mode
export WESTON_DRM_MIRROR=1
export WESTON_DRM_KEEP_RATIO=1

# Disable DRM plane hardware scale feature
# export WESTON_DRM_DISABLE_PLANE_SCALE=1

# Tag file for freezing weston display
# export WESTON_FREEZE_DISPLAY=/tmp/.freeze_weston

# Dynamic config file path, config examples:
# echo "compositor:state:sleep" > /tmp/.weston_drm.conf
# echo "compositor:state:off" > /tmp/.weston_drm.conf
# echo "compositor:state:on" > /tmp/.weston_drm.conf
# echo "output:DSI-1:off" >> /tmp/.weston_drm.conf
# echo "output:eDP-1:freeze" >> /tmp/.weston_drm.conf
# echo "output:all:rotate90" >> /tmp/.weston_drm.conf
# echo "output:all:rect=<100,20,1636,2068>" >> /tmp/.weston_drm.conf
# echo "output:HDMI-A-1:mode=800x600" >> /tmp/.weston_drm.conf
# export WESTON_DRM_CONFIG=/tmp/.weston_drm.conf

export QT_QPA_PLATFORM=wayland
