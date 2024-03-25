import store from '@/store'

/// Useful to set intersection threshold
export function buildThresholdList() {
  const thresholds = [];
  const numSteps = 20;

  for (let i = 1.0; i <= numSteps; i++) {
    const ratio = i / numSteps;
    thresholds.push(ratio);
  }

  thresholds.push(0);
  return thresholds;
}

export function showLoader() {
  store.commit('setLoaderState', true)
}

export function closeLoader() {
  store.commit('setLoaderState', false)
}

export function isArray(val) {
  return val.constructor.name == 'Array'
}

export function isNumber(val) {
  return typeof val == 'number'
}

export function isString(val) {
  return typeof val == 'string'
}

export function isOnlyDigits(value) {
  if (!value) return false
  const regex = /^[0-9.]+$/
  return regex.test(value.toString())
}

export function toCssVal(value, unit = 'px') {
  if (isString(value)) {
    return value
  } else if (isNumber(value)) {
    return `${value}${unit}`
  } else if (isArray(value)) {
    const length = value.length

    // helper
    function setValue(val, i) {
      if (isString(val)) return val

      const def = `${val}${unit}`
      switch (length) {
        case 2: {
          if (i === 1) return `${val}em`
        } break;
        case 3: {
          if (i === 1) return `${val}vw`
        } break;
      }

      return def
    }

    const formatValue = value.map((e, i) => setValue(e, i)).join(',')

    switch (length) {
      case 1: return setValue(value.at(0))
      case 2: return `max(${formatValue})`
      default: return `clamp(${formatValue})`
    }
  }
}

export function getUrlFromFile(file) {
  if (!file) return null
  return URL.createObjectURL(file)
}

export async function getFileFromUrl(url, type = 'image/jpeg') {
  const
    response = await fetch(url),
    blob = await response.blob(),
    filename = getFilenameFromUrl(url),
    file = new File([blob], filename, { type })
  
  return file
}

export function getFilenameFromUrl(url) {
  const path = url.split('/')

  // Gets the last part, which should be the name of the file
  return path[path.length - 1]
}

export async function getImageSize(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = function(event) {
      const img = new Image();
      img.onload = function() {
        const width = img.width;
        const height = img.height;
        resolve({ width, height });
      };
      img.src = event.target.result;
    };
    reader.onerror = (error) => reject(error);

    reader.readAsDataURL(file);
  });
}
