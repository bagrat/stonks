export class PhxHook {
  static makeNew(...args) {
    const phxHookWrapperClass = this

    const hook = {
      _wrapper: null,
      _debug: "debug",
      mounted() {
        const wrapper = new phxHookWrapperClass(...args)
        wrapper.hook = this
        wrapper.el = this.el
        wrapper.liveSocket = this.liveSocket
        wrapper.pushEvent = this.pushEvent && this.pushEvent.bind(this)
        wrapper.pushEventTo = this.pushEventTo && this.pushEventTo.bind(this)
        wrapper.handleEvent = this.handleEvent && this.handleEvent.bind(this)
        wrapper.upload = this.upload && this.upload.bind(this)
        wrapper.uploadTo = this.uploadTo && this.uploadTo.bind(this)

        getAllFunctions(wrapper)
          .map((fn) => {
            return [wrapper[fn]?.name, fn]
          })
          .filter(([name, _]) => !!name)
          .filter(([name, _]) => {
            return name.startsWith("on")
          })
          .map(([name, fn]) => {
            const event = name.replace("on", "").toLowerCase()
            wrapper.el.addEventListener(event, wrapper[fn].bind(wrapper))
          })

        this._wrapper = wrapper
        return this._wrapper.mounted()
      },
      beforeUpdate() {
        return this._wrapper.beforeUpdate()
      },
      updated() {
        return this._wrapper.updated()
      },
      destroyed() {
        return this._wrapper.destroyed()
      },
      disconnected() {
        return this._wrapper.disconnected()
      },
      reconnected() {
        return this._wrapper.reconnected()
      },
    }

    return hook
  }

  pushEvent(...args) {
    return this.hook.pushEvent(...args)
  }

  pushEventTo(...args) {
    return this.hook.pushEventTo(...args)
  }

  handleEvent(...args) {
    return this.hook.handleEvent(...args)
  }

  upload(...args) {
    return this.hook.upload(...args)
  }

  uploadTo(...args) {
    return this.hook.uploadTo(...args)
  }

  mounted() {}
  beforeUpdate() {}
  updated() {}
  destroyed() {}
  disconnected() {}
  reconnected() {}
}

function getAllFunctions(obj) {
  let properties = new Set()
  let currentObj = obj

  while (currentObj) {
    const descriptors = Object.getOwnPropertyDescriptors(currentObj)

    Object.keys(descriptors).forEach((prop) => {
      if (typeof descriptors[prop].value === "function") {
        properties.add(prop)
      }
    })

    currentObj = Object.getPrototypeOf(currentObj)
  }

  return [...properties]
}
