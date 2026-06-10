<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <div>
        <!--<h2 class="text-2xl font-bold text-gray-700">Cấu hình Xác thực</h2>-->
        <p class="text-gray-500 text-sm mt-1">Chọn phương thức xác thực cho người dùng cuối (Email OTP hoặc Firebase SMS)</p>
      </div>
      <el-button @click="fetchConfig" circle>🔄</el-button>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Active Provider -->
      <div class="lte-card">
        <div class="lte-card-header">🔐 Phương thức xác thực hiện tại</div>
        <div class="lte-card-body">
          <el-form :model="config" label-position="top" v-loading="loading">
            <el-form-item label="Provider đang kích hoạt">
              <el-radio-group v-model="config.activeProvider" class="w-full">
                <div class="grid grid-cols-1 gap-3 w-full">
                  <div :class="['border-2 rounded-lg p-4 cursor-pointer transition-all',
                    config.activeProvider === 'EMAIL' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300']"
                    @click="config.activeProvider = 'EMAIL'">
                    <el-radio label="EMAIL" size="large">
                      <div>
                        <span class="font-bold text-base">📧 Email OTP</span>
                        <p class="text-sm text-gray-500 mt-1">Gửi mã OTP qua email (Resend API)</p>
                      </div>
                    </el-radio>
                  </div>
                  <div :class="['border-2 rounded-lg p-4 cursor-pointer transition-all',
                    config.activeProvider === 'FIREBASE' ? 'border-orange-500 bg-orange-50' : 'border-gray-200 hover:border-gray-300']"
                    @click="config.activeProvider = 'FIREBASE'">
                    <el-radio label="FIREBASE" size="large">
                      <div>
                        <span class="font-bold text-base">📱 Firebase SMS</span>
                        <p class="text-sm text-gray-500 mt-1">Gửi OTP qua SMS (Firebase Auth)</p>
                      </div>
                    </el-radio>
                  </div>
                </div>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="Giới hạn OTP / giờ">
              <el-input-number v-model="config.maxOtpPerHour" :min="1" :max="20" controls-position="right" class="!w-full" />
              <div class="text-xs text-gray-400 mt-1">Số lần gửi OTP tối đa mỗi giờ cho 1 người dùng</div>
            </el-form-item>

            <el-form-item label="Cho phép Fallback">
              <el-switch v-model="config.fallbackEnabled" active-text="Bật" inactive-text="Tắt" />
              <div class="text-xs text-gray-400 mt-1">Tự động chuyển sang provider phụ nếu provider chính lỗi</div>
            </el-form-item>
          </el-form>
        </div>
      </div>

      <!-- Provider Config Details -->
      <div class="space-y-6">
        <!-- Email Config -->
        <div class="lte-card">
          <div class="lte-card-header">📧 Cấu hình Email (Resend)</div>
          <div class="lte-card-body">
            <el-form label-position="top">
              <el-form-item label="API Key">
                <el-input v-model="emailConfig.apiKey" placeholder="re_xxxxxxxxxx" show-password />
              </el-form-item>
              <el-form-item label="From Email">
                <el-input v-model="emailConfig.fromEmail" placeholder="noreply@dtals.vn" />
              </el-form-item>
            </el-form>
          </div>
        </div>

        <!-- Firebase Config -->
        <div class="lte-card">
          <div class="lte-card-header">🔥 Cấu hình Firebase</div>
          <div class="lte-card-body">
            <el-form label-position="top">
              <el-form-item label="Project ID">
                <el-input v-model="firebaseConfig.projectId" placeholder="my-project-id" />
              </el-form-item>
              <el-form-item label="API Key">
                <el-input v-model="firebaseConfig.apiKey" placeholder="AIzaSy..." show-password />
              </el-form-item>
            </el-form>
          </div>
        </div>
      </div>
    </div>

    <!-- Save Button -->
    <div class="mt-6 flex justify-end">
      <el-button type="primary" size="large" :loading="saving" @click="saveConfig">
        💾 Lưu cấu hình
      </el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { ElMessage } from 'element-plus';
import { adminAuthConfigApi } from '../../services/api';

const loading = ref(false);
const saving = ref(false);

const config = reactive({
  activeProvider: 'EMAIL' as 'EMAIL' | 'FIREBASE',
  maxOtpPerHour: 3,
  fallbackEnabled: false,
});

const emailConfig = reactive({ apiKey: '', fromEmail: '' });
const firebaseConfig = reactive({ projectId: '', apiKey: '' });

const fetchConfig = async () => {
  loading.value = true;
  try {
    const res = await adminAuthConfigApi.get();
    const d = res.data;
    
    if (d.status) {
      config.activeProvider = d.status.activeProvider || 'EMAIL';
      config.maxOtpPerHour = d.status.maxOtpPerHour ?? 3;
      config.fallbackEnabled = d.status.fallbackEnabled ?? false;
    } else {
      config.activeProvider = d.activeProvider || 'EMAIL';
      config.maxOtpPerHour = d.maxOtpPerHour ?? 3;
      config.fallbackEnabled = d.fallbackEnabled ?? false;
    }
    
    const emConf = d.configs?.emailConfig || d.emailConfig;
    if (emConf) {
      emailConfig.apiKey = emConf.apiKey || '';
      emailConfig.fromEmail = emConf.fromEmail || '';
    }
    
    const fbConf = d.configs?.firebaseConfig || d.firebaseConfig;
    if (fbConf) {
      firebaseConfig.projectId = fbConf.projectId || '';
      firebaseConfig.apiKey = fbConf.apiKey || '';
    }
  } catch (e: any) {
    ElMessage.warning('Chưa có cấu hình xác thực, sử dụng mặc định.');
  } finally {
    loading.value = false;
  }
};

const saveConfig = async () => {
  saving.value = true;
  try {
    await adminAuthConfigApi.update({
      activeProvider: config.activeProvider,
      maxOtpPerHour: config.maxOtpPerHour,
      fallbackEnabled: config.fallbackEnabled,
      emailConfig: { apiKey: emailConfig.apiKey, fromEmail: emailConfig.fromEmail },
      firebaseConfig: { projectId: firebaseConfig.projectId, apiKey: firebaseConfig.apiKey },
    });
    ElMessage.success('Đã lưu cấu hình xác thực!');
  } catch (e: any) {
    ElMessage.error('Lỗi: ' + (e.response?.data?.message || e.message));
  } finally {
    saving.value = false;
  }
};

onMounted(fetchConfig);
</script>
