import QtQuick
import QtTest

TestCase {
  name: "LockSettling"

  Component { id: policyComponent; LockTiming {} }
  Component {
    id: screenComponent
    QtObject {
      property string name: "eDP-1"
      property int x: 0
      property int y: 0
      property int width: 1920
      property int height: 1080
    }
  }

  function makePolicy() {
    var screen = createTemporaryObject(screenComponent, this)
    var policy = createTemporaryObject(policyComponent, this, { testScreens: [screen] })
    return { policy: policy, screen: screen }
  }

  function request(policy) {
    policy.lockRequested = true
    policy.queueSessionLock()
  }

  function test_startupWaits() {
    var p = makePolicy().policy
    request(p)
    wait(250)
    compare(p.sessionLocked, false)
    tryCompare(p, "sessionLocked", true, 1000)
  }

  function test_stableDisplayLocksImmediately() {
    var p = makePolicy().policy
    wait(600)
    request(p)
    compare(p.sessionLocked, true)
  }

  function test_lastGeometryChangeOwnsDeadline() {
    var state = makePolicy()
    var p = state.policy
    wait(600)
    state.screen.width = 1280
    request(p)
    wait(300)
    state.screen.height = 720
    wait(300)
    compare(p.sessionLocked, false, "the second geometry change extends settling")
    // Repeated requests must not extend the wait beyond the output's deadline.
    p.queueSessionLock()
    tryCompare(p, "sessionLocked", true, 350)
  }

  function test_hotplugBeforeRequestStillWaits() {
    var p = makePolicy().policy
    wait(600)
    p.testScreens = [createTemporaryObject(screenComponent, this, { name: "HDMI-A-1" })]
    wait(200)
    request(p)
    compare(p.sessionLocked, false)
    tryCompare(p, "sessionLocked", true, 450)
  }

  function test_noScreensWaitsForValidOutput() {
    var p = createTemporaryObject(policyComponent, this)
    wait(600)
    request(p)
    wait(150)
    compare(p.sessionLocked, false)
    var screen = createTemporaryObject(screenComponent, this, { name: "", width: 0 })
    p.testScreens = [screen]
    wait(600)
    compare(p.sessionLocked, false, "an invalid output cannot acquire the lock")
    screen.name = "eDP-1"
    screen.width = 1920
    wait(250)
    compare(p.sessionLocked, false, "a newly valid output must settle too")
    tryCompare(p, "sessionLocked", true, 1000)
  }
}
