<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <div>
        <!--<h2 class="text-2xl font-bold text-gray-700">Quản lý Phân quyền</h2>-->
        <p class="text-gray-500 text-sm mt-1">Cấu hình các nhóm quyền (Role) và gán quyền chi tiết</p>
      </div>
      <div class="flex gap-2">
        <el-button @click="fetchRoles" circle>🔄</el-button>
        <el-button type="primary" @click="openCreateDialog">+ Thêm Role</el-button>
      </div>
    </div>

    <!-- Roles Table -->
    <div class="lte-card">
      <div class="lte-card-header flex justify-between">
        <span>Danh sách Role</span>
        <el-tag type="info" size="small">{{ roles.length }} roles</el-tag>
      </div>
      <div class="lte-card-body">
        <el-table :data="roles" v-loading="loading" stripe border>
          <el-table-column prop="name" label="Tên Role" width="200">
            <template #default="{ row }">
              <span class="font-bold text-blue-600">{{ row.name }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="description" label="Mô tả" min-width="200" />
          <el-table-column label="Quyền" width="150" align="center">
            <template #default="{ row }">
              <el-tag type="info" size="small" round>
                {{ row.permissions ? row.permissions.length : 0 }} quyền
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="Thao tác" width="150" align="center">
            <template #default="{ row }">
              <el-button size="small" type="primary" text @click="openEditDialog(row)">Sửa</el-button>
              <el-button size="small" type="danger" text @click="deleteRole(row)">Xóa</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </div>

    <!-- Create/Edit Dialog -->
    <el-dialog v-model="dialogVisible" :title="isEdit ? 'Cập nhật Role' : 'Tạo Role Mới'" width="600px" destroy-on-close>
      <el-form :model="form" :rules="rules" ref="formRef" label-position="top">
        <el-form-item label="Tên Role (Mã định danh)" prop="name">
          <el-input v-model="form.name" placeholder="VD: ADMIN, MANAGER, TECH..." :disabled="isEdit" />
          <div class="text-xs text-gray-400 mt-1">Viết hoa, không dấu, nối bằng gạch dưới</div>
        </el-form-item>

        <el-form-item label="Danh sách Quyền (Permissions)">
          <div class="border rounded-lg p-4 max-h-[300px] overflow-y-auto bg-gray-50 w-full">
            <el-checkbox-group v-model="form.permissions">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
                <el-checkbox v-for="perm in permissions" :key="perm" :label="perm" class="!mr-0 w-full">
                  {{ perm }}
                </el-checkbox>
              </div>
            </el-checkbox-group>
            <div v-if="permissions.length === 0" class="text-center text-gray-400 py-4">
              Không tải được danh sách quyền.
            </div>
          </div>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">Hủy</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">
          {{ isEdit ? 'Cập nhật' : 'Tạo mới' }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { adminRoleApi } from '../../services/api';

const loading = ref(false);
const roles = ref<any[]>([]);
const permissions = ref<string[]>([]);
const dialogVisible = ref(false);
const submitting = ref(false);
const isEdit = ref(false);
const formRef = ref();

const form = reactive({ id: '', name: '', permissions: [] as string[] });
const rules = { name: [{ required: true, message: 'Vui lòng nhập tên Role', trigger: 'blur' }] };

const fetchRoles = async () => {
  loading.value = true;
  try {
    const res = await adminRoleApi.list();
    roles.value = res.data || [];
  } catch (e: any) {
    ElMessage.error('Lỗi tải Role: ' + (e.response?.data?.message || e.message));
  } finally {
    loading.value = false;
  }
};

const fetchPermissions = async () => {
  try {
    const res = await adminRoleApi.getPermissions();
    permissions.value = res.data || [];
  } catch (e) {
    console.warn('Failed to load permissions', e);
  }
};

const openCreateDialog = () => {
  isEdit.value = false;
  form.id = '';
  form.name = '';
  form.permissions = [];
  dialogVisible.value = true;
};

const openEditDialog = (role: any) => {
  isEdit.value = true;
  form.id = role.id;
  form.name = role.name;
  form.permissions = role.permissions
    ? role.permissions.map((p: any) => (typeof p === 'string' ? p : p.code))
    : [];
  dialogVisible.value = true;
};

const handleSubmit = async () => {
  if (!formRef.value) return;
  await formRef.value.validate(async (valid: boolean) => {
    if (!valid) return;
    submitting.value = true;
    try {
      const payload = { name: form.name, permissions: form.permissions };
      if (isEdit.value) {
        await adminRoleApi.update(form.id, payload);
        ElMessage.success('Cập nhật Role thành công');
      } else {
        await adminRoleApi.create(payload);
        ElMessage.success('Tạo Role mới thành công');
      }
      dialogVisible.value = false;
      fetchRoles();
    } catch (e: any) {
      ElMessage.error('Lỗi: ' + (e.response?.data?.message || e.message));
    } finally {
      submitting.value = false;
    }
  });
};

const deleteRole = (role: any) => {
  ElMessageBox.confirm(
    `Bạn có chắc chắn muốn xóa Role "${role.name}"? Hành động này không thể hoàn tác.`,
    'Xác nhận xóa',
    { confirmButtonText: 'Xóa', cancelButtonText: 'Hủy', type: 'warning' }
  ).then(async () => {
    try {
      await adminRoleApi.delete(role.id);
      ElMessage.success('Đã xóa Role');
      fetchRoles();
    } catch (e: any) {
      ElMessage.error('Lỗi: ' + (e.response?.data?.message || e.message));
    }
  }).catch(() => {});
};

onMounted(() => {
  fetchRoles();
  fetchPermissions();
});
</script>
