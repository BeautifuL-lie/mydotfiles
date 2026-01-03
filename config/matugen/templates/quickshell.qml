pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  property QtObject colors

  colors: QtObject {
    <*for name, value in colors *>
        property string {{name}}: "{{value.default.hex}}";
    <* endfor *>
    }
}
