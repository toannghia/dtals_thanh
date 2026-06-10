<template>
  <div>
    <!-- Filters -->
    <el-card shadow="hover" class="!border-none !rounded-xl mb-6">
      <div class="flex gap-4 flex-wrap items-center">
        <el-input 
          v-model="queryParams.search" 
          placeholder="Tìm theo tên đăng nhập, email..." 
          class="!w-64" 
          clearable 
          @keyup.enter="fetchUsers"
          @clear="fetchUsers"
        >
          <template #prefix>🔍</template>
        </el-input>
        <el-button type="primary" @click="fetchUsers">Tìm kiếm</el-button>
        <div class="ml-auto flex items-center gap-2">
          <el-switch v-model="hideEndUsers" @change="fetchUsers" />
          <span class="text-sm font-medium text-gray-600">Ẩn End User</span>
          <el-button type="success" @click="openDialog()">
            <template #icon>➕</template>
            Thêm nhân viên
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- System User Table -->
    <el-card shadow="hover" class="!border-none !rounded-xl" v-loading="loading">
      <el-table :data="users" stripe border>
        <el-table-column label="STT" width="70" align="center">
          <template #default="{ $index }">
            {{ (queryParams.page - 1) * queryParams.limit + $index + 1 }}
          </template>
        </el-table-column>
        <el-table-column label="Nhân viên" min-width="200">
          <template #default="{ row }">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-indigo-500 flex items-center justify-center text-white text-xs font-bold shrink-0">
                <span v-if="row.fullName">{{ row.fullName.charAt(0).toUpperCase() }}</span>
                <span v-else-if="row.username">{{ row.username.charAt(0).toUpperCase() }}</span>
                <span v-else>A</span>
              </div>
              <div>
                <div class="font-medium">{{ row.username }}</div>
                <div class="text-xs text-gray-400">{{ row.email || 'Không có email' }}</div>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="roleName" label="Vai trò" width="150">
          <template #default="{ row }">
            <el-tag size="small" :type="getRoleColor(row.role?.name || row.roleName)">
              {{ row.role?.name || row.roleName || '—' }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="status" label="Trạng thái" width="130">
          <template #default="{ row }">
            <el-tag :type="row.status === 'ACTIVE' ? 'success' : 'danger'" size="small">
              {{ row.status === 'ACTIVE' ? '✅ Hoạt động' : '🔴 Đã khóa' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Ngày tạo" width="120">
          <template #default="{ row }">
            {{ row.createdAt ? new Date(row.createdAt).toLocaleDateString('vi-VN') : '—' }}
          </template>
        </el-table-column>
        <el-table-column label="Đăng nhập cuối" width="160">
          <template #default="{ row }">
            <span v-if="row.lastLoginAt" class="text-sm">{{ new Date(row.lastLoginAt).toLocaleString('vi-VN') }}</span>
            <span v-else class="text-gray-400 text-sm">Chưa đăng nhập</span>
          </template>
        </el-table-column>
        <el-table-column label="Thao tác" width="200" align="center" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="primary" plain @click="openDialog(row)">Sửa</el-button>
            <el-button size="small" type="danger" plain @click="confirmDelete(row)">Xóa</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <div class="mt-4 flex justify-end">
        <el-pagination 
          background 
          layout="total, sizes, prev, pager, next" 
          :total="total" 
          v-model:current-page="queryParams.page"
          v-model:page-size="queryParams.limit"
          :page-sizes="[10, 20, 50, 100]"
          @current-change="fetchUsers"
          @size-change="fetchUsers"
        />
      </div>
    </el-card>

    <!-- Create/Edit Dialog -->
    <el-dialog 
      v-model="dialogVisible" 
      :title="editingUser ? 'Sửa Nhân Viên' : 'Thêm Nhân Viên Mới'" 
      width="500px"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="120px" class="mt-4">
        <el-form-item v-if="editingUser" label="ID Hệ thống">
          <el-input :model-value="editingUser.id" disabled class="font-mono" />
        </el-form-item>
        <el-form-item label="Phân quyền" prop="roleName">
          <el-select v-model="form.roleName" placeholder="Chọn vai trò" class="w-full">
            <el-option v-for="role in roles" :key="role.name" :label="role.name" :value="role.name" />
          </el-select>
        </el-form-item>

        <el-form-item label="Username" prop="username">
          <el-input v-model="form.username" placeholder="Nhập tên đăng nhập" :disabled="!!editingUser" />
        </el-form-item>
        
        <el-form-item label="Họ và tên" prop="fullName">
          <el-input v-model="form.fullName" placeholder="Nhập họ và tên" />
        </el-form-item>

        <el-form-item label="Email" prop="email">
          <el-input v-model="form.email" placeholder="Nhập email" />
        </el-form-item>
        
        <el-form-item label="Mật khẩu" prop="password" :required="!editingUser">
          <el-input v-model="form.password" type="password" show-password placeholder="Nhập mật khẩu" />
          <div v-if="editingUser" class="text-xs text-gray-400 mt-1">Để trống nếu không muốn đổi mật khẩu</div>
        </el-form-item>

        <el-form-item label="Trạng thái" prop="status">
          <el-select v-model="form.status" class="w-full">
            <el-option label="Hoạt động" value="ACTIVE" />
            <el-option label="Khóa" value="INACTIVE" />
          </el-select>
        </el-form-item>

        <el-form-item v-if="form.roleName === 'GOV' || form.roleName === 'AUTHORITY'" label="Tỉnh quản lý" prop="assignedProvinces">
          <el-select v-model="form.assignedProvinces" multiple collapse-tags placeholder="Chọn các tỉnh quản lý" class="w-full">
            <el-option label="TẤT CẢ (Cả nước)" value="ALL" />
            <el-option v-for="p in provinceList" :key="p" :label="p" :value="p" />
          </el-select>
          <div class="text-xs text-gray-400 mt-1">Chọn "TẤT CẢ" để cấp quyền quản lý toàn quốc.</div>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">Hủy</el-button>
          <el-button type="primary" @click="saveUser" :loading="saving">Lưu lại</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue';
import { adminUserApi, adminRoleApi } from '../../services/api';
import { ElMessage, ElMessageBox } from 'element-plus';
import type { FormInstance, FormRules } from 'element-plus';

const loading = ref(false);
const users = ref<any[]>([]);
const total = ref(0);

const queryParams = ref({
  page: 1,
  limit: 20,
  search: ''
});

const hideEndUsers = ref(true);
const roles = ref<any[]>([]);

// Dialog state
const dialogVisible = ref(false);
const saving = ref(false);
const editingUser = ref<any>(null);
const formRef = ref<FormInstance>();

const form = reactive({
  username: '',
  fullName: '',
  email: '',
  password: '',
  status: 'ACTIVE',
  roleName: '',
  assignedProvinces: [] as string[]
});

const provinceList = [
  "An Giang", "Bắc Ninh", "Cao Bằng", "Cà Mau", "Cần Thơ", 
  "Gia Lai", "Huế", "Hà Nội", "Hà Tĩnh", "Hưng Yên", 
  "Hải Phòng", "Khánh Hòa", "Lai Châu", "Lào Cai", "Lâm Đồng", 
  "Lạng Sơn", "Nghệ An", "Ninh Bình", "Phú Thọ", "Quảng Ngãi", 
  "Quảng Ninh", "Quảng Trị", "Sơn La", "TP. Hồ Chí Minh", "Thanh Hóa", 
  "Thái Nguyên", "Tuyên Quang", "Tây Ninh", "Vĩnh Long", "Điện Biên", 
  "Đà Nẵng", "Đắk Lắk", "Đồng Nai", "Đồng Tháp"
];

const getRoleColor = (roleName: string) => {
  if (!roleName) return 'info';
  const name = roleName.toUpperCase();
  if (name.includes('SUPER_ADMIN')) return 'danger';
  if (name.includes('ADMIN')) return 'warning';
  if (name.includes('GOV') || name.includes('AUTHORITY')) return 'primary';
  if (name.includes('ACCOUNTANT')) return 'success';
  return 'info';
};

const rules = reactive<FormRules>({
  username: [
    { required: true, message: 'Vui lòng nhập tên đăng nhập', trigger: 'blur' },
    { min: 3, message: 'Username phải từ 3 ký tự', trigger: 'blur' }
  ],
  email: [
    { required: true, message: 'Vui lòng nhập email', trigger: 'blur' },
    { type: 'email', message: 'Email không hợp lệ', trigger: 'blur' }
  ],
  password: [
    { 
      validator: (_rule: any, value: any, callback: any) => {
        if (!editingUser.value && !value) {
          callback(new Error('Vui lòng nhập mật khẩu'));
        } else if (value && value.length < 6) {
          callback(new Error('Mật khẩu phải từ 6 ký tự'));
        } else {
          callback();
        }
      },
      trigger: 'blur'
    }
  ]
});

const fetchRoles = async () => {
  try {
    const res = await adminRoleApi.list();
    roles.value = res.data || [];
  } catch (error) {
    console.error('Lỗi khi tải danh sách quyền:', error);
  }
};

const fetchUsers = async () => {
  loading.value = true;
  try {
    const res = await adminUserApi.list({
      page: queryParams.value.page,
      limit: queryParams.value.limit,
      search: queryParams.value.search || undefined,
    });
    
    if (res.data && res.data.data) {
      let records = res.data.data || [];
      // Filter out END_USER if toggle is on
      if (hideEndUsers.value) {
        records = records.filter((u: any) => {
          // Check role name. Role might be a string, or inside an array of roles, or object
          const roleName = u.role?.name || u.roleName || u.role;
          return roleName !== 'END_USER' && roleName !== 'end_user';
        });
      }
      users.value = records;
      total.value = res.data.meta?.total || records.length;
    } else {
      users.value = [];
      total.value = 0;
    }
  } catch (error: any) {
    console.error('Error fetching system users:', error);
    ElMessage.error(error.response?.data?.message || 'Không thể tải danh sách nhân viên');
  } finally {
    loading.value = false;
  }
};

const openDialog = (user?: any) => {
  editingUser.value = user || null;
  if (user) {
    form.username = user.username || '';
    form.fullName = user.fullName || '';
    form.email = user.email || '';
    form.password = '';
    form.status = user.status || 'ACTIVE';
    form.roleName = user.role?.name || user.roleName || '';
    form.assignedProvinces = user.assignedProvinces || [];
  } else {
    form.username = '';
    form.fullName = '';
    form.email = '';
    form.password = '';
    form.status = 'ACTIVE';
    form.roleName = '';
    form.assignedProvinces = [];
  }
  dialogVisible.value = true;
  // Clear validation after next tick
  setTimeout(() => formRef.value?.clearValidate(), 0);
};

const saveUser = async () => {
  if (!formRef.value) return;
  await formRef.value.validate(async (valid) => {
    if (valid) {
      saving.value = true;
      try {
        if (!editingUser.value) {
          // Create new user requires username and password, status not allowed by CreateUserDto
          const createPayload: any = {
            username: form.username,
            password: form.password,
            fullName: form.fullName,
            email: form.email,
          };
          if (form.roleName) createPayload.roleName = form.roleName;
          if (form.assignedProvinces && form.assignedProvinces.length > 0) {
            createPayload.assignedProvinces = form.assignedProvinces;
          }
          await adminUserApi.create(createPayload);
          ElMessage.success('Thêm nhân viên thành công');
        } else {
          // Update user
          const updatePayload: any = {
            fullName: form.fullName,
            email: form.email,
            status: form.status,
          };
          if (form.password) updatePayload.password = form.password;
          if (form.roleName) updatePayload.roleName = form.roleName;
          updatePayload.assignedProvinces = form.assignedProvinces;
          
          await adminUserApi.update(editingUser.value.id, updatePayload);
          ElMessage.success('Cập nhật nhân viên thành công');
        }
        
        dialogVisible.value = false;
        fetchUsers();
      } catch (error: any) {
        ElMessage.error(error.response?.data?.message || 'Lỗi khi lưu thông tin');
      } finally {
        saving.value = false;
      }
    }
  });
};

const confirmDelete = (row: any) => {
  ElMessageBox.confirm(
    `Bạn có chắc chắn muốn xóa người dùng "${row.username}" không?`,
    'Xác nhận xóa',
    {
      confirmButtonText: 'Đồng ý',
      cancelButtonText: 'Hủy',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await adminUserApi.delete(row.id);
      ElMessage.success('Xóa thành công');
      fetchUsers();
    } catch (error: any) {
      ElMessage.error(error.response?.data?.message || 'Lỗi khi xóa người dùng');
    }
  }).catch(() => { /* do nothing */ });
};

onMounted(() => {
  fetchRoles();
  fetchUsers();
});
</script>

<style scoped>
/* Optional styling */
</style>
