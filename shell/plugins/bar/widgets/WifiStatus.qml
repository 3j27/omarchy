import QtQuick
import Quickshell.Networking
import qs.Ui
import "../../panels/network/Model.js" as NetworkModel

BarWidget {
  id: root
  moduleName: "omarchy.wifi-status"

  readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
  readonly property var wifiDevice: findWifiDevice()
  readonly property var connectedNetwork: findConnectedNetwork()
  readonly property bool connected: !!wifiDevice && wifiDevice.connected
  readonly property int signalStrength: connectedNetwork ? Math.round((connectedNetwork.signalStrength || 0) * 100) : 0
  readonly property string icon: connected ? NetworkModel.wifiIconFor(signalStrength) : "󰤮"

  function findWifiDevice() {
    for (var i = 0; i < networkDevices.length; i++) {
      var device = networkDevices[i]
      if (device && device.type === DeviceType.Wifi) return device
    }
    return null
  }

  function findConnectedNetwork() {
    var networks = wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    for (var i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].connected) return networks[i]
    }
    return null
  }

  BarIconButton {
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    tooltipText: root.connected ? "Wi-Fi connected" : "Wi-Fi disconnected"

    onPressed: function() {
      if (root.bar && root.bar.shell) root.bar.shell.summon("omarchy.network", "{}")
    }
  }
}
