import { toCssVal } from "./functions";

export default (app) => {
  /// font directive
  app.directive('font', {
    created(el, binding) {
      const { value, arg, modifiers } = binding

      const styles = (item) => {
        if (arg) item.style.fontFamily = arg
        item.style.fontSize = toCssVal(value)
      }

      if (modifiers.all) {
        for (const element of el.children) styles(element)
        if (modifiers.in) return
      }

      styles(el)
    },
  })


  /// flex directive
  app.directive('flex', {
    created(el, binding) {
      const { value, modifiers } = binding

      el.style.display = 'flex'

      if (value.column) el.style.flexDirection = 'column'
      if (value.align) el.style.alignItems = 'center'
      if (value.alignStart) el.style.alignItems = 'flex-start'
      if (value.alignEnd) el.style.alignItems = 'flex-end'
      if (value.justify) el.style.justifyContent = 'center'
      if (value.justifyStart) el.style.justifyContent = 'flex-start'
      if (value.justifyEnd) el.style.justifyContent = 'flex-end'
      if (value.center) {
        el.style.alignItems = 'center'
        el.style.justifyContent = 'center'
      }
      if (value.space) el.style.justifyContent = 'space-between'
      if (value.spaceA) el.style.justifyContent = 'space-around'
      if (value.spaceE) el.style.justifyContent = 'space-evenly'
      if (value.wrap) el.style.flexWrap = 'wrap'

      if (value.flex)
        if (modifiers.in)
          for (const item of el.children) item.style.flex = value.flexx
        else
          el.style.flex = value.flex
    },
  })

  app.directive('size', {
    created(el, binding) {
      const { value : val } = binding
      const value = Object.fromEntries(
        Object.entries(val).map(e => {
          const [key, val] = e
          return [key, toCssVal(val)]
        })
      )

      if (value.w) el.style.width = value.w
      if (value.maxw) el.style.maxWidth = value.maxw
      if (value.minw) el.style.minWidth = value.minw
      if (value.h) el.style.height = value.h
      if (value.maxh) el.style.maxHeight = value.maxh
      if (value.minh) el.style.minHeight = value.minh
    }
  })
}
