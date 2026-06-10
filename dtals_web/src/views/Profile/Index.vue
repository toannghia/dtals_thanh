<template>
  <div>
    <h2 class="text-2xl font-bold text-gray-700 mb-6">Thông tin tài khoản</h2>

    <div class="max-w-4xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-6">
      <!-- Left: Avatar & Role -->
      <div class="space-y-4">
        <div class="lte-card">
          <div class="lte-card-body text-center py-6">
            <div class="relative group inline-block">
              <el-avatar :size="100" :src="userForm.avatar || undefined"
                class="bg-blue-100 text-blue-600 text-4xl font-bold border-4 border-white shadow-md">
                {{ !userForm.avatar ? (userForm.fullName?.charAt(0)?.toUpperCase() || 'A') : '' }}
              </el-avatar>
              <div
                class="absolute inset-0 flex items-center justify-center bg-black/40 rounded-full opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                @click="triggerAvatarUpload">
                <span class="text-white text-xl">📷</span>
              </div>
              <input type="file" ref="fileInput" class="hidden" accept="image/*" @change="handleAvatarChange" />
            </div>
            <h3 class="text-xl font-bold text-gray-800 mt-3">{{ userForm.fullName || userForm.username }}</h3>
            <el-tag effect="plain" type="info" class="mt-1">{{ userForm.role || 'Admin' }}</el-tag>
          </div>
        </div>

        <div class="lte-card">
          <div class="lte-card-header">🔑 Phân quyền</div>
          <div class="lte-card-body text-sm text-gray-600">
            <p class="mb-2">Vai trò hiện tại:</p>
            <el-tag>{{ userForm.role || 'SUPER_ADMIN' }}</el-tag>
          </div>
        </div>
      </div>

      <!-- Right: Tabs -->
      <div class="md:col-span-2">
        <div class="lte-card">
          <div class="lte-card-body !p-0">
            <el-tabs v-model="activeTab" class="profile-tabs">
              <!-- Tab 1: Info -->
              <el-tab-pane label="Thông tin chung" name="info">
                <div class="p-6">
                  <h4 class="text-lg font-bold mb-4">📝 Cập nhật thông tin</h4>
                  <el-form ref="infoFormRef" :model="userForm" label-position="top">
                    <el-form-item label="Tên đăng nhập">
                      <el-input v-model="userForm.username" disabled />
                    </el-form-item>
                    <el-form-item label="Họ và tên" prop="fullName"
                      :rules="[{ required: true, message: 'Nhập họ tên', trigger: 'blur' }]">
                      <el-input v-model="userForm.fullName" />
                    </el-form-item>
                    <el-form-item label="Email">
                      <el-input v-model="userForm.email" placeholder="email@dtals.vn" />
                    </el-form-item>
                    <el-form-item label="Số điện thoại">
                      <el-input v-model="userForm.phoneNumber" placeholder="0987654321" />
                    </el-form-item>
                    <div class="flex justify-end mt-4">
                      <el-button type="primary" :loading="loading" @click="handleUpdateInfo">Lưu thay đổi</el-button>
                    </div>
                  </el-form>
                </div>
              </el-tab-pane>

              <!-- Tab 2: Password -->
              <el-tab-pane label="Đổi mật khẩu" name="password">
                <div class="p-6">
                  <h4 class="text-lg font-bold mb-4">🔒 Bảo mật tài khoản</h4>
                  <el-alert title="Bạn sẽ cần đăng nhập lại sau khi đổi mật khẩu" type="warning" show-icon
                    :closable="false" class="mb-4" />
                  <el-form ref="passwordFormRef" :model="passwordForm" :rules="passwordRules" label-position="top">
                    <el-form-item label="Mật khẩu mới" prop="newPassword">
                      <el-input v-model="passwordForm.newPassword" type="password" show-password />
                    </el-form-item>
                    <el-form-item label="Xác nhận mật khẩu" prop="confirmPassword">
                      <el-input v-model="passwordForm.confirmPassword" type="password" show-password />
                    </el-form-item>
                    <div class="flex justify-end mt-4">
                      <el-button type="danger" :loading="passwordLoading" @click="handleChangePassword">
                        Đổi mật khẩu
                      </el-button>
                    </div>
                  </el-form>
                </div>
              </el-tab-pane>
            </el-tabs>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { ElMessage } from 'element-plus';
import { useAuthStore } from '../../store/auth';
import { authApi } from '../../services/api';
import { useRouter } from 'vue-router';
import type { FormInstance, FormRules } from 'element-plus';

const authStore = useAuthStore();
const router = useRouter();
const activeTab = ref('info');
const loading = ref(false);
const passwordLoading = ref(false);
const fileInput = ref<HTMLInputElement>();
const infoFormRef = ref<FormInstance>();
const passwordFormRef = ref<FormInstance>();

const userForm = reactive({
  username: '',
  fullName: '',
  email: '',
  phoneNumber: '',
  role: '',
  avatar: '',
});

const passwordForm = reactive({ newPassword: '', confirmPassword: '' });

const passwordRules = reactive<FormRules>({
  newPassword: [
    { required: true, message: 'Vui lòng nhập mật khẩu mới', trigger: 'blur' },
    { min: 6, message: 'Mật khẩu phải có ít nhất 6 ký tự', trigger: 'blur' },
  ],
  confirmPassword: [
    { required: true, message: 'Vui lòng xác nhận mật khẩu', trigger: 'blur' },
    {
      validator: (_: any, value: string, callback: any) => {
        value !== passwordForm.newPassword
          ? callback(new Error('Mật khẩu xác nhận không khớp'))
          : callback();
      },
      trigger: 'blur',
    },
  ],
});

onMounted(async () => {
  if (!authStore.user) await authStore.fetchProfile();
  const u = authStore.user;
  if (u) {
    userForm.username = u.username || '';
    userForm.fullName = u.fullName || u.full_name || '';
    userForm.email = u.email || '';
    userForm.phoneNumber = u.phoneNumber || '';
    // Role may be object {name:'SUPER_ADMIN'} or string
    const role = (u as any).role;
    userForm.role = typeof role === 'object' ? role?.name || JSON.stringify(role) : role || '';
    userForm.avatar = u.avatar || '';
  }
});

const triggerAvatarUpload = () => fileInput.value?.click();

const handleAvatarChange = async (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (!target.files?.[0]) return;
  const file = target.files[0];

  if (file.size / 1024 > 500) {
    ElMessage.warning('Vui lòng chọn ảnh dưới 500KB');
    if (fileInput.value) fileInput.value.value = '';
    return;
  }

  // Convert to base64 data URL for simple avatar storage
  const reader = new FileReader();
  reader.onload = async (e) => {
    const dataUrl = e.target?.result as string;
    try {
      await authApi.updateProfile({ avatar: dataUrl });
      userForm.avatar = dataUrl;
      await authStore.fetchProfile();
      ElMessage.success('Cập nhật ảnh đại diện thành công');
    } catch (err) {
      ElMessage.error('Lỗi khi cập nhật avatar');
    }
  };
  reader.readAsDataURL(file);
  if (fileInput.value) fileInput.value.value = '';
};

const handleUpdateInfo = async () => {
  if (!infoFormRef.value) return;
  await infoFormRef.value.validate(async (valid) => {
    if (!valid) return;
    loading.value = true;
    try {
      await authApi.updateProfile({
        fullName: userForm.fullName,
        email: userForm.email,
        phoneNumber: userForm.phoneNumber,
      });
      await authStore.fetchProfile();
      ElMessage.success('Cập nhật thông tin thành công');
    } catch (e: any) {
      ElMessage.error(e.response?.data?.message || 'Có lỗi xảy ra');
    } finally {
      loading.value = false;
    }
  });
};

const handleChangePassword = async () => {
  if (!passwordFormRef.value) return;
  await passwordFormRef.value.validate(async (valid) => {
    if (!valid) return;
    passwordLoading.value = true;
    try {
      await authApi.updateProfile({ password: passwordForm.newPassword } as any);
      ElMessage.success('Đổi mật khẩu thành công. Đang đăng xuất...');
      setTimeout(() => { authStore.logout(); router.push('/login'); }, 1500);
    } catch (e: any) {
      ElMessage.error(e.response?.data?.message || 'Có lỗi xảy ra');
    } finally {
      passwordLoading.value = false;
    }
  });
};
</script>

<style scoped>
.profile-tabs :deep(.el-tabs__header) {
  margin-bottom: 0;
  padding: 0 20px;
  border-bottom: 1px solid #f0f0f0;
}
.profile-tabs :deep(.el-tabs__nav-wrap::after) {
  height: 1px;
}
</style>
