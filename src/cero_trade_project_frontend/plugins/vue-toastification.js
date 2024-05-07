import Toast, { POSITION, TYPE } from "vue-toastification";

// Import the CSS or use your own!
import "vue-toastification/dist/index.css";
import "@/assets/styles/components/vue-toastification.scss";

export default (app) => {
  // documentation: https://github.com/Maronato/vue-toastification/tree/next

  const options = {
    // You can set your default options here
    position: POSITION.TOP_RIGHT,
    toastDefaults: {
      // ToastOptions object for each type of toast
      [TYPE.INFO]: {
        position: POSITION.BOTTOM_RIGHT
      },
      [TYPE.ERROR]: {
        timeout: 10000,
      },
      [TYPE.SUCCESS]: {
        timeout: 5000,
        hideProgressBar: true,
      }
    }
  };

  app.use(Toast, options);
}
