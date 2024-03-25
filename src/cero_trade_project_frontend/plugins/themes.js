const defaultColors = {
    white: '#fff',
    black: '#000',
    
    textGrey: '#b9b9b9',
    error: '#B00020',
    info: '#2196F3',
    success: '#4CAF50',
    warning: '#FB8C00',
  }
  
  const light = {
    dark: false,
    colors: {
      'background-app': '#ffffff',
      background: '#FFFFFF',
      surface: '#FFFFFF',
      foreground: '#000000',
      label: '#6e6e6e',
  
      primary: '#C6F221',
      'primary-darken-1': '#3700B3',
      secondary: '#02a6d0',
      'secondary-darken-1': '#018786',
      tertiary: '#475467',
      'tertiary-darken-1': '#018786',
      accent: '#162c59',
  
      ...defaultColors,
    },
  }
  
  const dark = {
    dark: true,
    colors: {
      ...defaultColors,
    },
  }
  
  export default { light, dark }
  