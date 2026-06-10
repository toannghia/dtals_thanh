<template>
  <div>
    <div class="flex justify-end mb-4">
      <el-button @click="fetchConfig" circle>🔄</el-button>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Connection Status & Links -->
      <div class="lte-card">
        <div class="lte-card-header">🔌 Trạng thái & Cấu hình URL</div>
        <div class="lte-card-body" v-loading="loading">
          <div class="flex items-center gap-6 mb-2">
            <div class="flex items-center gap-2">
              <span class="text-gray-600 font-medium">Trạng thái:</span>
              <el-tag :type="config.isEnabled ? 'success' : 'info'" size="large" effect="dark">
                {{ config.isEnabled ? '✅ Đang hoạt động' : '⏸️ Tạm tắt' }}
              </el-tag>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-gray-600 font-medium">Môi trường:</span>
              <el-tag :type="config.isSandbox ? 'warning' : 'danger'" size="large">
                {{ config.isSandbox ? '🧪 Sandbox (Test)' : '🚀 Production' }}
              </el-tag>
            </div>
          </div>
          
          <el-form label-position="top">
            <div class="grid grid-cols-2 gap-4">
              <el-form-item label="Kích hoạt PayOS" class="!mb-4">
                <div class="flex flex-col items-start">
                  <el-switch v-model="config.isEnabled" active-text="Bật" inactive-text="Tắt" />
                  <span class="text-xs text-gray-500 mt-2 leading-tight">Khi tắt, không tạo link mới.</span>
                </div>
              </el-form-item>
              <el-form-item label="Chế độ Sandbox" class="!mb-4">
                <div class="flex flex-col items-start">
                  <el-switch v-model="config.isSandbox" active-text="Sandbox" inactive-text="Production" />
                  <span class="text-xs text-gray-500 mt-2 leading-tight">Môi trường test PayOS.</span>
                </div>
              </el-form-item>
            </div>
            
            <el-form-item label="Return URL (Thanh toán thành công)">
              <el-input v-model="config.returnUrl" placeholder="https://your-domain.com/user/payment-result" clearable />
            </el-form-item>
            <el-form-item label="Cancel URL (Hủy thanh toán)">
              <el-input v-model="config.cancelUrl" placeholder="https://your-domain.com/user/orders" clearable />
            </el-form-item>
            <el-form-item label="Webhook URL">
              <el-input v-model="config.webhookUrl" placeholder="https://api.your-domain.com/payment/webhook" clearable />
            </el-form-item>
          </el-form>
        </div>
      </div>

      <!-- API Keys -->
      <div class="lte-card h-fit">
        <div class="lte-card-header">🔑 API Keys</div>
        <div class="lte-card-body" v-loading="loading">
          <el-alert type="info" :closable="false" class="!mb-4">
            <template #title>
              Lấy thông tin từ <a href="https://my.payos.vn" target="_blank" class="text-blue-600 underline font-semibold">my.payos.vn</a> → Tích hợp → API Keys
            </template>
          </el-alert>
          <el-form label-position="top">
            <el-form-item label="Client ID">
              <el-input v-model="config.clientId" placeholder="Nhập Client ID từ PayOS" clearable />
            </el-form-item>
            <el-form-item label="API Key">
              <el-input v-model="config.apiKey" placeholder="Nhập API Key" show-password clearable>
                <template #prefix><span class="text-gray-400">🔐</span></template>
              </el-input>
              <div class="text-xs text-gray-400 mt-1">Key sẽ được mã hóa khi lưu. Hiển thị dạng ••••xxxx.</div>
            </el-form-item>
            <el-form-item label="Checksum Key">
              <el-input v-model="config.checksumKey" placeholder="Nhập Checksum Key" show-password clearable>
                <template #prefix><span class="text-gray-400">🔐</span></template>
              </el-input>
              <div class="text-xs text-gray-400 mt-1">Dùng để xác thực HMAC_SHA256 cho Webhook.</div>
            </el-form-item>
            <el-form-item label="Partner Code (tuỳ chọn)">
              <el-input v-model="config.partnerCode" placeholder="Mã đối tác (nếu có)" clearable />
            </el-form-item>
          </el-form>
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
import { adminPayosConfigApi } from '../../services/api';

const loading = ref(false);
const saving = ref(false);

const config = reactive({
  clientId: '',
  apiKey: '',
  checksumKey: '',
  partnerCode: '',
  returnUrl: '',
  cancelUrl: '',
  webhookUrl: '',
  isSandbox: true,
  isEnabled: false,
});

const fetchConfig = async () => {
  loading.value = true;
  try {
    const res = await adminPayosConfigApi.get();
    const d = res.data;
    config.clientId = d.clientId || '';
    config.apiKey = d.apiKey || '';
    config.checksumKey = d.checksumKey || '';
    config.partnerCode = d.partnerCode || '';
    config.returnUrl = d.returnUrl || '';
    config.cancelUrl = d.cancelUrl || '';
    config.webhookUrl = d.webhookUrl || '';
    config.isSandbox = d.isSandbox ?? true;
    config.isEnabled = d.isEnabled ?? false;
  } catch {
    ElMessage.warning('Chưa có cấu hình PayOS, sử dụng mặc định.');
  } finally {
    loading.value = false;
  }
};

const saveConfig = async () => {
  saving.value = true;
  try {
    await adminPayosConfigApi.update({ ...config });
    ElMessage.success('Đã lưu cấu hình PayOS!');
    await fetchConfig(); // Reload to get masked keys
  } catch (e: any) {
    ElMessage.error('Lỗi: ' + (e.response?.data?.message || e.message));
  } finally {
    saving.value = false;
  }
};

onMounted(fetchConfig);
</script>
