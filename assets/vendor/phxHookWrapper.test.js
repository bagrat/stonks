import { PhxHook } from "./phxHookWrapper"

class TestHook extends PhxHook {
  constructor(
    mountResult,
    beforeUpdateResult,
    updatedResult,
    destroyedResult,
    disconnectedResult,
    reconnectedResult
  ) {
    super()

    this.mountResult = mountResult
    this.beforeUpdateResult = beforeUpdateResult
    this.updatedResult = updatedResult
    this.destroyedResult = destroyedResult
    this.disconnectedResult = disconnectedResult
    this.reconnectedResult = reconnectedResult
  }
  mounted() {
    return 12
  }
  beforeUpdate() {
    return 34
  }
  updated() {
    return 56
  }
  destroyed() {
    return 78
  }
  disconnected() {
    return 90
  }
  reconnected() {
    return 1011
  }

  pushEvent() {}
}

describe("phxHook", () => {
  it("it should be possible to provide a hook as a class", () => {
    const hook = TestHook.makeNew(12, 34, 56, 78, 90, 1011)
    hook.pushEvent = function () {
      return this
    }.bind(hook)

    expect(hook._debug).toBe("debug")

    expect(hook.mounted.bind(hook)()).toBe(12)
    expect(hook.beforeUpdate.bind(hook)()).toBe(34)
    expect(hook.updated.bind(hook)()).toBe(56)
    expect(hook.destroyed.bind(hook)()).toBe(78)
    expect(hook.disconnected.bind(hook)()).toBe(90)
    expect(hook.reconnected.bind(hook)()).toBe(1011)

    expect(hook._wrapper.pushEvent()).toBe(hook)
  })
})
