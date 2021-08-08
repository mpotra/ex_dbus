defmodule StatusNotifierItemInterface do
  use ExDBus.Schema

  node do
    interface "org.kde.StatusNotifierItem" do
      property("Category", "s", :read)
      property("Id", "s", :read)
      property("Title", "s", :read)
      property("Status", "s", :read)
      property("WindowId", "i", :read)

      # An additional path to add to the theme search path to find the icons specified above.
      property("IconThemePath", "s", :read)
      property("Menu", "o", :read)
      property("ItemIsMenu", "b", :read)

      # main icon
      # names are preferred over pixmaps
      property("IconName", "s", :read)
      # struct containing width, height and image data
      property("IconPixmap", "a(iiay)", :read) do
        annotation("org.qtproject.QtDBus.QtTypeName", "QXdgDBusImageVector")
      end

      # struct containing width, height and image data
      property("OverlayIconName", "s", :read)

      property("OverlayIconPixmap", "a(iiay)", :read) do
        annotation("org.qtproject.QtDBus.QtTypeName", "QXdgDBusImageVector")
      end

      # Requesting attention icon
      property("AttentionIconName", "s", :read)

      # same definition as image
      property("AttentionIconPixmap", "a(iiay)", :read) do
        annotation("org.qtproject.QtDBus.QtTypeName", "QXdgDBusImageVector")
      end

      # tooltip data

      # (iiay) is an image
      property("ToolTip", "(sa(iiay)ss)", :read) do
        annotation("org.qtproject.QtDBus.QtTypeName", "QXdgDBusToolTipStruct")
      end

      # interaction: the systemtray wants the application to do something
      method "ContextMenu" do
        # we're passing the coordinates of the icon, so the app knows where to put the popup window -->
        arg("x", "i", :in)
        arg("y", "i", :in)
      end

      method "Activate" do
        arg("x", "i", :in)
        arg("y", "i", :in)
      end

      method "SecondaryActivate" do
        arg("x", "i", :in)
        arg("y", "i", :in)
      end

      method "Scroll" do
        arg("delta", "i", :in)
        arg("orientation", "s", :in)
      end

      # Signals: the client wants to change something in the status-->
      signal("NewTitle")
      signal("NewIcon")
      signal("NewAttentionIcon")
      signal("NewOverlayIcon")
      signal("NewMenu")
      signal("NewToolTip")

      signal "NewStatus" do
        arg("status", "s")
      end
    end
  end
end
