import store from '@/store'
import imageCompression from 'browser-image-compression';
import variables from "@/mixins/variables";

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

export function setAppLoader(value) {
  store.commit('setAppLoaderState', value)
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

export function formatAmount(value, {
  symbol,
  symbolSuffixed = true,
  currency,
  locale = variables.defaultLocale,
  maxDecimals = variables.defaultMaxDecimals,
  minimumFractionDigits = variables.defaultMaxDecimals,
  compact = false,
  removeThousandSeparator
}) {
  // Parse the string as a number. If parsing fails, use 0.0.
  value = parseFloat(Number(value).toString().replace(",", "")) || 0.0;

  // Use the Intl.NumberFormat API to format the value.
  let formatter

  if (compact) {
    formatter = new Intl.NumberFormat(
      'en-US', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 1,
      notation: 'compact',
      compactDisplay: 'short',
    });
  } else if (currency) {
    formatter = new Intl.NumberFormat(
      locale, {
      style: 'currency',
      currency: currency,
      minimumFractionDigits: minimumFractionDigits,
      maximumFractionDigits: maxDecimals,
    });
  } else {
    formatter = new Intl.NumberFormat(
      locale, {
      minimumFractionDigits: minimumFractionDigits,
      maximumFractionDigits: maxDecimals,
    });
  }

  let formattedValue = formatter.format(value).trim();

  if (symbol) {
    formattedValue = formattedValue.replace(/[^0-9.,\s]+/g, symbol)

    if (symbolSuffixed) {
      formattedValue = `${formattedValue}${symbol}`
    } else {
      formattedValue = `${symbol}${formattedValue}`
    }
  }

  if (removeThousandSeparator) {
    const thousandSeparator = getDecimalSeparator(locale) === ',' ? '.' : ','
    formattedValue = formattedValue.split(thousandSeparator).join('')
  }

  return formattedValue
}

export function unformatAmount(formattedValue, {
  symbol,
  locale = variables.defaultLocale,
  symbolSuffixed = true,
}) {
  if (!formattedValue) return 0

  if (symbol && symbolSuffixed) {
    formattedValue = formattedValue.slice(0, -symbol.length)
  }
  else if (symbol) {
    formattedValue = formattedValue.slice(symbol.length)
  }

  if (getDecimalSeparator(locale) === ',') {
    formattedValue = formattedValue.replaceAll('.', '')
    formattedValue = formattedValue.replace(',', '.')
  } else {
    formattedValue = formattedValue.replaceAll(',', '')
  }

  return parseFloat(formattedValue)
}

export function maxDecimals(value, max = 3) {
  if (!value || value === '0') return 0
  else if (Number(value) % 1 == 0) return value

  const splitted = value.toString().split("."),
    decimalsFiltered = splitted[1].substring(0, splitted[1].length > max ? max : splitted[1].length);

  splitted.pop();
  splitted.push(decimalsFiltered);
  return parseFloat(splitted.join("."));
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

export function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  let i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(decimals)} ${suffixes[i]}`;
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

export async function getImageBlob(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = function() {
      const blob = new Blob([reader.result], {type: file.type});
      resolve(blob);
    };
    reader.onerror = (error) => reject(error);

    reader.readAsDataURL(file);
  });
}

export async function getImageArrayBuffer(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = function(evt) {
      if (evt.target.readyState === FileReader.DONE) {
        const arrayBuffer = evt.target.result,
        byteArray = new Uint8Array(arrayBuffer),
        fileByteArray = []

        for (const byte of byteArray) fileByteArray.push(byte);
        resolve(fileByteArray);
      }
    };
    reader.onerror = (error) => reject(error);

    reader.readAsArrayBuffer(file);
  });
}

export function getFileFromArrayBuffer(array, fileName) {
  const blob = new Blob([array], { type: 'application/octet-stream' });
  const file = new File([blob], fileName, { type: 'application/octet-stream' });
  return file;
}

export function getUrlFromArrayBuffer(array, type) {
  type ??= 'image/jpeg'
  let blob = new Blob([array], {type});
  let url = URL.createObjectURL(blob);
  return url
}

export async function fileCompression(file, options) {
  const blob = await imageCompression(file, options || {
    maxSizeMB: 1,
    maxWidthOrHeight: 1920,
    useWebWorker: true,
    initialQuality: 0.7,
  })

  return new File([blob], blob.name)
}

export function convertE8SToICP(e8s) { return e8s / variables.e8sEquivalence }

export function convertICPToE8S(icp) { return icp * variables.e8sEquivalence }

export function shortPrincipalId(principalId) {
  const splitted = principalId?.split('-');
  if (!splitted) return ''

  return `${splitted[0]}...${splitted[splitted.length - 1]}`
}