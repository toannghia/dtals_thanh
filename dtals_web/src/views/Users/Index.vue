<template>
  <div>
    <!-- Filters -->
    <el-card shadow="hover" class="!border-none !rounded-xl mb-6">
      <div class="flex gap-4 flex-wrap">
        <el-input v-model="queryParams.search" placeholder="Tìm theo tên, email, sđt, username..."
          class="!w-64" clearable @change="fetchUsers" @clear="fetchUsers" />
        <el-select v-model="queryParams.status" placeholder="Trạng thái" clearable class="!w-48"
          @change="fetchUsers" @clear="fetchUsers">
          <el-option label="Tất cả" value="" />
          <el-option label="✅ Hoạt động" value="ACTIVE" />
          <el-option label="⏳ Chưa kích hoạt" value="INACTIVE" />
          <el-option label="🔴 Đã khóa" value="BLOCKED" />
          <el-option label="⏳ Chờ xóa" value="DELETION_REQUESTED" />
          <el-option label="🗑️ Đã xóa" value="DELETED" />
        </el-select>
        <el-button type="primary" @click="fetchUsers">Lọc</el-button>
        <div class="ml-auto">
          <el-button type="success" @click="openAddDialog">
            <template #icon>➕</template>
            Thêm người dùng
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- User Table -->
    <el-card shadow="hover" class="!border-none !rounded-xl" v-loading="loading">
      <el-table :data="users" stripe border>
        <el-table-column label="STT" width="70" align="center">
          <template #default="{ $index }">
            {{ (queryParams.page - 1) * queryParams.limit + $index + 1 }}
          </template>
        </el-table-column>
        <el-table-column label="Người dùng" min-width="200">
          <template #default="{ row }">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white text-xs font-bold shrink-0">
                {{ (row.fullName || row.username || 'U').charAt(0).toUpperCase() }}
              </div>
              <div>
                <router-link :to="`/users/${row.id}`" class="font-medium text-blue-600 hover:text-blue-800 hover:underline block truncate">{{ row.fullName || 'Chưa cập nhật' }}</router-link>
                <div class="text-xs text-gray-400">{{ row.email || 'Không có email' }}</div>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="Username" width="140">
          <template #default="{ row }">
            <router-link :to="`/users/${row.id}`" class="font-medium text-gray-800 hover:text-blue-600 hover:underline">{{ row.username || '—' }}</router-link>
          </template>
        </el-table-column>
        <el-table-column prop="phoneNumber" label="SĐT" width="130" />
        <el-table-column label="Trạng thái" width="160">
          <template #default="{ row }">
            <el-tag :type="statusTag(row.status).type" size="small">
              {{ statusTag(row.status).label }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="eKYC" width="130">
          <template #default="{ row }">
            <el-tag :type="row.kycStatus === 'VERIFIED' ? 'success' : 'info'" size="small">
              {{ row.kycStatus || 'Chưa làm' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Ngày tạo" width="120">
          <template #default="{ row }">
            {{ new Date(row.createdAt).toLocaleDateString('vi-VN') }}
          </template>
        </el-table-column>
        <el-table-column label="Đăng nhập cuối" width="150">
          <template #default="{ row }">
            <span v-if="row.lastLoginAt" class="text-xs">{{ new Date(row.lastLoginAt).toLocaleString('vi-VN') }}</span>
            <span v-else class="text-gray-400 text-xs">Chưa đăng nhập</span>
          </template>
        </el-table-column>
        <el-table-column label="Thao tác" width="260" align="center" fixed="right">
          <template #default="{ row }">
            <div class="flex gap-1 justify-center flex-wrap">
              <el-button size="small" type="primary" plain @click="showDetail(row)">Chi tiết</el-button>
              <el-button size="small" type="warning" plain @click="openEditDialog(row)">Sửa</el-button>
              <el-button v-if="row.status === 'INACTIVE'" size="small" type="success" plain @click="activateUser(row)">Kích hoạt</el-button>
              <el-button v-if="row.status !== 'DELETED'" size="small" type="danger" plain @click="deleteUser(row)">Xóa</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <div class="mt-4 flex justify-end">
        <el-pagination background layout="total, sizes, prev, pager, next" :total="total"
          v-model:current-page="queryParams.page" v-model:page-size="queryParams.limit"
          :page-sizes="[10, 20, 50, 100]" @current-change="fetchUsers" @size-change="fetchUsers" />
      </div>
    </el-card>

    <!-- Detail Dialog -->
    <el-dialog v-model="detailVisible" title="Chi tiết người dùng" width="600px">
      <div v-if="detailUser" class="space-y-3">
        <div class="grid grid-cols-2 gap-4">
          <div><span class="text-gray-500 text-sm">ID:</span><div class="font-mono text-xs text-gray-600 mt-1 break-all">{{ detailUser.id }}</div></div>
          <div><span class="text-gray-500 text-sm">Username:</span><div class="font-medium mt-1">{{ detailUser.username }}</div></div>
          <div><span class="text-gray-500 text-sm">Họ và tên:</span><div class="font-medium mt-1">{{ detailUser.fullName || '—' }}</div></div>
          <div><span class="text-gray-500 text-sm">Email:</span><div class="mt-1">{{ detailUser.email || '—' }}</div></div>
          <div><span class="text-gray-500 text-sm">Số điện thoại:</span><div class="mt-1">{{ detailUser.phoneNumber || '—' }}</div></div>
          <div><span class="text-gray-500 text-sm">Trạng thái:</span><div class="mt-1"><el-tag :type="statusTag(detailUser.status).type" size="small">{{ statusTag(detailUser.status).label }}</el-tag></div></div>
          <div><span class="text-gray-500 text-sm">eKYC:</span><div class="mt-1">{{ detailUser.kycStatus || 'Chưa làm' }}</div></div>
          <div><span class="text-gray-500 text-sm">Ngày tạo:</span><div class="mt-1">{{ new Date(detailUser.createdAt).toLocaleString('vi-VN') }}</div></div>
        </div>
      </div>
      <template #footer>
        <el-button @click="detailVisible = false">Đóng</el-button>
      </template>
    </el-dialog>

    <!-- Add/Edit Dialog -->
    <el-dialog v-model="formVisible" :title="isEditing ? 'Sửa người dùng' : 'Thêm người dùng'" width="500px">
      <el-form :model="formData" label-width="120px" label-position="top">
        <el-form-item label="Username" required>
          <el-input v-model="formData.username" :disabled="isEditing" placeholder="Tên đăng nhập" />
        </el-form-item>
        <el-form-item label="Họ và tên" required>
          <el-input v-model="formData.fullName" placeholder="Nhập họ và tên" />
        </el-form-item>
        <el-form-item label="Email" required>
          <el-input v-model="formData.email" placeholder="Email" />
        </el-form-item>
        <el-form-item label="Số điện thoại">
          <el-input v-model="formData.phoneNumber" placeholder="Số điện thoại" />
        </el-form-item>
        <el-form-item v-if="!isEditing" label="Mật khẩu" required>
          <el-input v-model="formData.password" type="password" placeholder="Nhập mật khẩu" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">Hủy</el-button>
        <el-button type="primary" :loading="formLoading" @click="handleSubmitForm">{{ isEditing ? 'Cập nhật' : 'Tạo mới' }}</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { adminEndUserApi } from '../../services/api';
import { ElMessage, ElMessageBox } from 'element-plus';

const router = useRouter();

const loading = ref(false);
const users = ref<any[]>([]);
const total = ref(0);

const queryParams = ref({
  page: 1,
  limit: 20,
  search: '',
  status: ''
});

// Detail dialog
const detailVisible = ref(false);
const detailUser = ref<any>(null);

// Add/Edit dialog
const formVisible = ref(false);
const formLoading = ref(false);
const isEditing = ref(false);
const editingUserId = ref('');
const formData = ref({
  username: '',
  fullName: '',
  email: '',
  phoneNumber: '',
  password: '',
});

const statusTag = (status: string) => {
  const map: Record<string, { type: string; label: string }> = {
    ACTIVE: { type: 'success', label: '✅ Hoạt động' },
    INACTIVE: { type: 'warning', label: '⏳ Chưa kích hoạt' },
    BLOCKED: { type: 'danger', label: '🔴 Đã khóa' },
    DELETION_REQUESTED: { type: 'warning', label: '⏳ Chờ xóa' },
    DELETED: { type: 'info', label: '🗑️ Đã xóa' },
  };
  return map[status] || { type: 'info', label: status || 'N/A' };
};

const fetchUsers = async () => {
  loading.value = true;
  try {
    const res = await adminEndUserApi.list({
      page: queryParams.value.page,
      limit: queryParams.value.limit,
      search: queryParams.value.search || undefined,
      status: queryParams.value.status || undefined
    });
    
    if (res.data?.data) {
      users.value = res.data.data || [];
      total.value = res.data.meta?.total || 0;
    } else {
      users.value = res.data || [];
      total.value = Array.isArray(res.data) ? res.data.length : 0;
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || 'Không thể tải danh sách người dùng');
  } finally {
    loading.value = false;
  }
};

const showDetail = async (row: any) => {
  router.push(`/users/${row.id}`);
};

const openAddDialog = () => {
  isEditing.value = false;
  editingUserId.value = '';
  formData.value = { username: '', fullName: '', email: '', phoneNumber: '', password: '' };
  formVisible.value = true;
};

const openEditDialog = (row: any) => {
  isEditing.value = true;
  editingUserId.value = row.id;
  formData.value = {
    username: row.username || '',
    fullName: row.fullName || '',
    email: row.email || '',
    phoneNumber: row.phoneNumber || '',
    password: '',
  };
  formVisible.value = true;
};

const handleSubmitForm = async () => {
  formLoading.value = true;
  try {
    if (isEditing.value) {
      await adminEndUserApi.update(editingUserId.value, {
        fullName: formData.value.fullName,
        email: formData.value.email,
        phoneNumber: formData.value.phoneNumber || undefined,
      });
      ElMessage.success('Cập nhật thành công');
    } else {
      // Create new user via end-user register endpoint (admin creating)
      const { default: api } = await import('../../services/api');
      await (api as any).post('/auth/register', {
        username: formData.value.username,
        fullName: formData.value.fullName,
        email: formData.value.email,
        phoneNumber: formData.value.phoneNumber || undefined,
        password: formData.value.password,
      });
      ElMessage.success('Tạo người dùng thành công');
    }
    formVisible.value = false;
    fetchUsers();
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || 'Thao tác thất bại');
  } finally {
    formLoading.value = false;
  }
};

const activateUser = async (row: any) => {
  try {
    await ElMessageBox.confirm(
      `Kích hoạt tài khoản "${row.fullName || row.username}"?`,
      'Xác nhận kích hoạt',
      { type: 'info' }
    );
    await adminEndUserApi.activate(row.id);
    ElMessage.success('Đã kích hoạt tài khoản');
    fetchUsers();
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.response?.data?.message || 'Lỗi');
  }
};

const deleteUser = async (row: any) => {
  try {
    await ElMessageBox.confirm(
      `Xóa tài khoản "${row.fullName || row.username}"? Tài khoản sẽ được chuyển sang trạng thái "Đã xóa".`,
      'Xác nhận xóa',
      { type: 'warning' }
    );
    await adminEndUserApi.softDelete(row.id);
    ElMessage.success('Đã xóa tài khoản');
    fetchUsers();
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.response?.data?.message || 'Lỗi');
  }
};

onMounted(() => {
  fetchUsers();
});
</script>

<style scoped>
/* Optional styling */
</style>
