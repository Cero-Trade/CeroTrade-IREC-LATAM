export default {
  methods: {
    customeDrag(event) {
      // select target
      const target = event.currentTarget;
      // set initial state
      let offset = [0,0], isDown = false;

      isDown = true;
      offset = [
        target.offsetTop - typeEvent(event).clientY,
        target.offsetLeft - typeEvent(event).clientX
      ];
      if (window.innerWidth <= 880) document.documentElement.style.overflow = "hidden"
      
      function typeEvent(event) {
        if (event.type.includes('mouse')) {
          return event
        } else if (event.type.includes('touch')) {
          return event.touches[0]
        }
      }
      
      const onMove = (e) => {
        const
          container = document.getElementById("home"),
          positionY = typeEvent(e).clientY + offset[0],
          positionX = typeEvent(e).clientX + offset[1],
          rangeYStart = 0, rangeYEnd = container.getBoundingClientRect().height - target.getBoundingClientRect().height,
          rangeXStart = 0, rangeXEnd = container.getBoundingClientRect().width - target.getBoundingClientRect().width;

        if (e.type.includes('mouse')) e.preventDefault();
        if (isDown && positionY > rangeYStart && positionY < rangeYEnd) {
          target.style.margin  = `initial`;
          target.style.bottom  = `initial`;
          
          target.style.top  = `${positionY}px`;
        };
        if (isDown && positionX > rangeXStart && positionX < rangeXEnd) {
          target.style.right  = `initial`;
          
          target.style.left  = `${positionX}px`;
        };
      }
      const removeHandlers = () => {
        window.onmouseup = null
        window.onmousemove = null
        window.ontouchend = null
        window.ontouchmove = null
        isDown = false
        if (window.innerWidth <= 880) document.documentElement.style.overflow = "auto"
      }
      
      // desktop
      window.onmouseup = () => removeHandlers()
      window.onmousemove = e => onMove(e)
      // mobile
      window.ontouchend = () => removeHandlers()
      window.ontouchmove = e => onMove(e)
    },
    
    customeDragOnly(event, {range, dir} = {range: undefined, dir: "vertical"}) {
      // set default range
      if (!range && dir === "vertical") range = 100
      else if (!range && dir === "horizontal") range = 20
      // select target
      const target = event.currentTarget;
      // set initial state
      let offset = [0,0], isDown = false;
      
      if (window.innerWidth <= 880) document.documentElement.style.overflow = "hidden"
      isDown = true;
      offset = [
        target.offsetTop - typeEvent(event).clientY,
        target.offsetLeft - typeEvent(event).clientX
      ];
      
      function typeEvent(event) {
        if (event.type.includes('mouse')) {
          return event
        } else if (event.type.includes('touch')) {
          return event.touches[0]
        }
      }
      
      const onMove = (e) => {
        const
          positionY = typeEvent(e).clientY + offset[0],
          positionX = typeEvent(e).clientX + offset[1];
        
        if (e.type.includes('mouse')) e.preventDefault();
        if (
          isDown && positionY > range
          && positionY < window.innerHeight - (range + 80)
          && dir === "vertical"
        ) target.style.top  = `${positionY}px`;
        if (
          isDown && positionX > range
          && positionX < window.innerWidth - (range + typeEvent(e).target.getBoundingClientRect().width + 30)
          && dir === "horizontal"
        ) target.style.left  = `${positionX}px`;
      }
      const removeHandlers = () => {
        window.onmouseup = null
        window.onmousemove = null
        window.ontouchend = null
        window.ontouchmove = null
        isDown = false
        if (window.innerWidth <= 880) document.documentElement.style.overflow = "auto"
      }
      
      // desktop
      window.onmouseup = () => removeHandlers()
      window.onmousemove = e => onMove(e)
      // mobile
      window.ontouchend = () => removeHandlers()
      window.ontouchmove = e => onMove(e)
    }
  }
}
