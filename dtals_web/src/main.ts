import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import 'element-plus/theme-chalk/dark/css-vars.css'
import router from './router'
import './style.css'
import App from './App.vue'

const app = createApp(App)
const pinia = createPinia()

// Global error handler for debugging blank screens
app.config.errorHandler = (err, _instance, info) => {
  console.error("Vue Global Error:", err, info);
  const errorMsg = err instanceof Error ? err.stack : String(err);
  document.body.innerHTML += `<div style="color:red;z-index:9999;position:fixed;top:0;left:0;background:white;padding:20px;width:100vw;height:100vh;overflow:auto;">
    <h1 style="font-size:24px;margin-bottom:10px;">Giao diện gặp lỗi (Vue Crash)</h1>
    <p><b>Info:</b> ${info}</p>
    <pre style="background:#f4f4f4;padding:15px;white-space:pre-wrap;font-family:monospace;">${errorMsg}</pre>
  </div>`;
};

app.use(pinia)
app.use(router)
app.use(ElementPlus)

app.mount('#app')

