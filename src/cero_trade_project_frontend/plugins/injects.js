import { ALERT_TYPE, SCROLL_TO } from '@/plugins/dictionary';

// TODO must to be updated
export default (app) => {
  // target-tooltip =========================================================================================================//
  const targetTooltip = (el, isResizeY = 0, isResizeX = 0) => {
    setTimeout(() => {
      const target = document.querySelector(el);
      document.documentElement.style.setProperty('--x-tooltip', `${target.getBoundingClientRect().left + isResizeX}px`)
      document.documentElement.style.setProperty('--y-tooltip', `${target.getBoundingClientRect().top + isResizeY}px`)
    }, 100);
  }
  /* usage:
    $targetTooltip(target) <-- if mounted
    $targetTooltip(target, y, x) <-- if resize
  */
  app.provide('targetTooltip', targetTooltip);


  // alerts =========================================================================================================//
  const alerts = (key, {title, desc, color, timeout, centered, top, bottom, left, right} = {}) => {
    if (ALERT_TYPE.values().includes(key)) {
      app.router.app.$children.find(data=>data.$el === document.querySelector(".v-application")).$refs.alerts.
        GenerateAlert(key, title, desc, color, timeout, centered, top, bottom, left, right);
    } else {
      throw new Error('Invalid key, try using any `ALERT_TYPE` value.')
    }
  }
  // usage $alert(key, {title, desc})
  app.provide('alert', alerts);


  // confirmMsg =========================================================================================================//
  const confirmMsg = ({title, desc, color, fSuccess, fCancel, fOpen} = {}) => {
    app.router.app.$children.find(data=>data.$el === document.querySelector(".v-application")).$refs.confirmMsg.
      GenerateMsg(fSuccess, fCancel, fOpen, title, desc, color);
  }
  // usage $alert(key, {title, desc})
  app.provide('confirmMsg', confirmMsg);


  // scroll-to =========================================================================================================//
  const scrollTo = id => {
    if (SCROLL_TO.values().includes(id)) {
      setTimeout(()=> {
        window.scrollTo(0, 1);
      }, 0);
    } else {
      const el = document.getElementById(id);
      if (el) {el.scrollIntoView(true)}
    }
  }
  // usage $scrollTo(id)
  app.provide('scrollTo', scrollTo);


  // load-cursor =========================================================================================================//
  const loadCursor = key => {
    if (key === true) {
      document.documentElement.style.cursor = "progress";
      document.documentElement.style.pointerEvents = "none";
    } else if (key === false) {
      document.documentElement.style.cursor = "initial";
      document.documentElement.style.pointerEvents = "all";
    } else {
      throw new Error("You must to pass Boolean")
    }
  }
  // usage $loadCursor(boolean)
  app.provide('loadCursor', loadCursor);


  // equalData =========================================================================================================//
  const equalData = (toData, fromData) => {
    for (const [keys, values] of Object.entries(toData)) {
      const dataValues = fromData[keys]
      if (typeof dataValues === "object") { Object.keys(values).forEach(key => { values[key] = dataValues[key] }) }
      else { toData[keys] = dataValues }
    }
    return toData
  }
  // usage $equalData(to, from)
  app.provide('equalData', equalData);


  // formData =========================================================================================================//
  const formData = (form) => {
    const formData = new FormData();
    for (const [keys, values] of Object.entries(form)) {
      // set empty string in null 
      if (form[keys] && typeof form[keys] === "object") {
        Object.keys(values).forEach(key => { values[key] ??= "" })
      } else { form[keys] ??= "" }
      
      // push to form data
      const
        excludeUrl = !(/\.(gif|jpg|jpeg|tiff|png)$/i).test(values),
        file = values?.type;
      if (typeof values === 'object' && !file) { formData.append(keys, JSON.stringify(values).toLowerCase()) } // if object only
      else if (file) { formData.append(keys, values) } // if file object
      else if (excludeUrl) { formData.append(keys, typeof values === 'string' ? values.toLowerCase() : values || "") } // else
    }
    return formData
  }
  // usage $formData(form)
  app.provide('formData', formData);
}
