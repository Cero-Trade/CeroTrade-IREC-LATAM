import { useToast } from "vue-toastification"

export default () => {
  const toast = useToast()

  // set-properties =========================================================================================================//
  if (!HTMLElement.prototype.setProperty) {
    HTMLElement.prototype.setProperty = function(props) {
      if (typeof props !== "object") throw new Error("You must use object arrangement")
      for (const [keys, values] of Object.entries(props)) {
        this.style.setProperty(`--${keys}`, values)
      }
    }
  }
  // htmlElement.setProperty({keys, values})  <--- example


  // to-capitalize =========================================================================================================//
  if (!String.prototype.toCapitalize) {
    String.prototype.toCapitalize = function() {
      return this.replace(/^\w/, (c) => c.toUpperCase());
    }
  }
  // string.toCapitalize() <-- example


  // to-kedabcase =========================================================================================================//
  if (!String.prototype.toKedabCase) {
    String.prototype.toKedabCase = function() {
      return this && this
        .match(/[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g)
        .map(x => x.toLowerCase())
        .join('-');
    }
  }
  // string.toKedabCase() <-- example


  // to-snakecase =========================================================================================================//
  if (!String.prototype.toSnakeCase) {
    String.prototype.toSnakeCase = function() {
    return this && this
      .match(/[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g)
      .map(x => x.toLowerCase())
      .join('_');
    }
  }
  // string.toSnakeCase() <-- example


  // limitString =========================================================================================================//
  if (!String.prototype.limitString) {
    String.prototype.limitString = function(limit) {
      if (this.length > limit) return `${this.substring(0, limit)}...`
      return this
    }
  }
  // string.limitString(limit) <-- example


  // cutString =========================================================================================================//
  if (!String.prototype.cutString) {
    String.prototype.cutString = function(start = 7, end = 4) {
      if (this.length > start + end) return `${this.substring(0, start)}...${this.substring(this.length - end, this.length)}`;
      return this
    }
  }
  // string.cutString(start, end) <-- example


  // toMonthName =========================================================================================================//
  if (!Number.prototype.toMonthName) {
    Number.prototype.toMonthName = function(length = 'short', lang = 'en-US') {
      const date = new Date();
      date.setMonth(this - 1);

      return date.toLocaleString(lang, { // <-- if [] empty will auto search locale
        month: length, // <-- can be long or short
      });
    }
  }
  // toMonthName(length, lang) <-- example


  // toDayName =========================================================================================================//
  if (!Number.prototype.toDayName) {
    Number.prototype.toDayName = function(length = 'long', lang = 'en-US') {
      const date = new Date()
      date.setDate(this - 1)

      return date.toLocaleString(lang, { // <-- if [] empty will auto search locale
        weekday: length, // <-- can be long or short
      });
    }
  }
  // toDayName(length, lang) <-- example


  // formatter =========================================================================================================//
  if (!Number.prototype.formatter) {
    Number.prototype.formatter = function(bloqMayus, decimals = 1) {
      if (Math.abs(this) > 999999999) {
        return `${Math.sign(this)*((Math.abs(this)/1000000000).toFixed(decimals))}${bloqMayus ? 'B' : 'b'}`
      } else if (Math.abs(this) > 999999) {
        return `${Math.sign(this)*((Math.abs(this)/1000000).toFixed(decimals))}${bloqMayus ? 'M' : 'm'}`
      } else if (Math.abs(this) > 999) {
        return `${Math.sign(this)*((Math.abs(this)/1000).toFixed(decimals))}${bloqMayus ? 'K' : 'k'}`
      } else {
        return Math.sign(this)*Math.abs(this)
      }
    }
  }
  // formatter(number) <-- example

  // groupBy =========================================================================================================//
  if (!Array.prototype.groupBy) {
    Array.prototype.groupBy = function(by) {
      return this.reduce((acc, obj) => {
        const key = obj[by];
        const curGroup = acc[key] ?? [];
        
        return { ...acc, [key]: [...curGroup, obj] };
      }, {});
    }
  }
  // groupBy(by) <-- example

  // groupAtPairs =========================================================================================================//
  if (!Array.prototype.groupAtPairs) {
    Array.prototype.groupAtPairs = function() {
      const pairs = this.filter((item, i) => i % 2 === 0);
      const unpairs = this.filter((item, i) => i % 2 !== 0);
      
      return unpairs.map((item, i) => [unpairs[i], pairs[i]])
    }
  }
  // groupAtPairs() <-- example

  // formatTime =========================================================================================================//
  if (!Number.prototype.formatTime) {
    Number.prototype.formatTime = function() {
      let minutes = Math.floor(this / 60);
      let seconds = this
      minutes = (minutes >= 10) ? minutes : "0" + minutes;
      seconds = Math.floor(seconds % 60);
      seconds = (seconds >= 10) ? seconds : "0" + seconds;
      return minutes + ":" + seconds;
    }
  }
  // formatTime() <-- example

  // pad =========================================================================================================//
  if (!Number.prototype.pad) {
    Number.prototype.pad = function(n) {
      return new Array(n).join('0').slice((n || 2) * -1) + this;
    }
  }
  // pad(2) <-- example


  // copy to clipboard =========================================================================================================//
  if (!String.prototype.copyToClipboard) {
    String.prototype.copyToClipboard = async function(message) {
      await navigator.clipboard.writeText(this)
      if (message) toast.info(message)
    }
  }
  // copyToClipboard() <-- example


  // split url =========================================================================================================//
  if (!String.prototype.splitUrl) {
    String.prototype.splitUrl = function(by, at) {
      return this.split(by).at(at)
    }
  }
  // splitUrl('?', 0) <-- example
}
