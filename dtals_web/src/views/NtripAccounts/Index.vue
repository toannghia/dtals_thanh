<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold text-gray-700">Quản lý Tài khoản NTRIP</h2>
      <el-button type="primary" @click="openCreateDialog">+ Thêm tài khoản</el-button>
    </div>

    <!-- Filters -->
    <div class="lte-card mb-4">
      <div class="lte-card-body flex gap-4 flex-wrap items-end">
        <el-input v-model="filters.keywords" placeholder="Tìm kiếm tên..." class="!w-56" clearable @clear="fetchData" />
        <el-select v-model="filters.enabled" placeholder="Trạng thái" clearable class="!w-40" @change="fetchData">
          <el-option label="Đang bật" :value="1" />
          <el-option label="Đã tắt" :value="0" />
        </el-select>
        <el-button type="primary" @click="fetchData">Tìm kiếm</el-button>
      </div>
    </div>

    <!-- Table -->
    <div class="lte-card">
      <div class="lte-card-header flex justify-between items-center">
        <span>Danh sách tài khoản NTRIP (Broadcast Users)</span>
        <el-tag type="info" size="small">Tổng: {{ total }}</el-tag>
      </div>
      <div class="lte-card-body">
        <el-table :data="accounts" stripe border v-loading="loading">
          <el-table-column label="STT" width="70" align="center">
            <template #default="{ $index }">
              {{ (filters.page - 1) * filters.size + $index + 1 }}
            </template>
          </el-table-column>
          <el-table-column prop="name" label="Tên tài khoản" min-width="160">
            <template #default="{ row }">
              <template v-if="row.owner">
                <router-link :to="`/users/${row.owner.id}`" class="text-blue-600 hover:text-blue-800 font-medium no-underline hover:underline truncate block">
                  {{ row.name }}
                </router-link>
              </template>
              <span v-else>{{ row.name }}</span>
            </template>
          </el-table-column>
          <el-table-column label="Chủ sở hữu" min-width="180">
            <template #default="{ row }">
              <template v-if="row.owner">
                <router-link :to="`/users/${row.owner.id}`" class="text-blue-600 hover:text-blue-800 font-medium no-underline hover:underline truncate block">
                  {{ row.owner.fullName || row.owner.email || 'Admin' }}
                </router-link>
              </template>
              <span v-else class="text-gray-400 italic">Không rõ</span>
            </template>
          </el-table-column>
          <el-table-column label="Trạng thái" width="130">
            <template #default="{ row }">
              <el-tag :type="row.enabled === 1 ? 'success' : 'danger'" size="small">
                {{ row.enabled === 1 ? '🟢 Active' : '🔴 Off' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="Đăng nhập" width="120" align="center">
            <template #default="{ row }">
              <el-tag v-if="onlineUserNames.has(row.name)" type="success" size="small" effect="light">
                🟢 Online
              </el-tag>
              <el-tag v-else type="info" size="small" effect="light">
                ⚪ Offline
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="Kết nối ĐT" width="100" align="center">
            <template #default="{ row }">{{ row.numOnline || 1 }}</template>
          </el-table-column>
          <el-table-column label="Bắt đầu" width="170">
            <template #default="{ row }">
              {{ row.startTime ? formatDate(row.startTime) : '—' }}
            </template>
          </el-table-column>
          <el-table-column label="Kết thúc" width="170">
            <template #default="{ row }">
              <span :class="{ 'text-red-500 font-bold': isExpired(row.endTime) }">
                {{ row.endTime ? formatDate(row.endTime) : '—' }}
              </span>
            </template>
          </el-table-column>
          <el-table-column label="Thao tác" width="220" align="center">
            <template #default="{ row }">
              <el-button size="small" type="primary" plain @click="openEditDialog(row)">Sửa</el-button>
              <el-button v-if="row.enabled === 1" size="small" type="warning" plain :loading="togglingId === row.id" @click="toggleEnabled(row, 0)">Tắt</el-button>
              <el-button v-else size="small" type="success" plain :loading="togglingId === row.id" @click="toggleEnabled(row, 1)">Bật</el-button>
              <el-button size="small" type="danger" plain @click="handleDelete(row)">Xóa</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div class="mt-4 flex justify-between items-center">
          <div class="flex items-center gap-2 text-sm text-gray-500">
            <span>Hiển thị</span>
            <el-select v-model="filters.size" class="!w-28" @change="onPageSizeChange">
              <el-option v-for="s in pageSizes" :key="s.value" :label="s.label" :value="s.value" />
            </el-select>
            <span>/ trang</span>
          </div>
          <el-pagination v-if="filters.size < 9999" background layout="prev, pager, next, total" :total="total"
            :page-size="filters.size" v-model:current-page="filters.page" @current-change="fetchData" />
          <el-tag v-else type="info">Hiển thị tất cả {{ total }} bản ghi</el-tag>
        </div>
      </div>
    </div>

    <!-- Create/Edit Dialog -->
    <el-dialog v-model="dialogVisible" :title="editingId ? 'Sửa tài khoản NTRIP' : 'Thêm tài khoản NTRIP'" width="500px">
      <el-form :model="form" label-position="top">
        <el-form-item v-if="editingId" label="ID Hệ thống:">
          <el-input :value="editingId" disabled />
        </el-form-item>
        <el-form-item label="Tên tài khoản (username NTRIP)" required>
          <el-input v-model="form.name" placeholder="VD: DTALS-USER-01" />
        </el-form-item>
        <el-form-item label="Mật khẩu" :required="!editingId">
          <el-input v-model="form.userPwd" type="password" :placeholder="editingId ? 'Để trống nếu không đổi' : 'Mật khẩu đăng nhập NTRIP'" show-password />
        </el-form-item>
        <el-form-item label="Số kết nối đồng thời">
          <el-input-number v-model="form.numOnline" :min="1" :max="10" />
        </el-form-item>
        <el-form-item label="Thời gian hiệu lực">
          <el-date-picker v-model="dateRange" type="datetimerange" range-separator="—"
            start-placeholder="Bắt đầu" end-placeholder="Kết thúc" class="!w-full" />
        </el-form-item>
        <el-form-item label="Trạng thái">
          <el-radio-group v-model="form.enabled">
            <el-radio :value="0">🔴 Off</el-radio>
            <el-radio :value="1">🟢 Active</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">Hủy</el-button>
        <el-button type="primary" :loading="saving" @click="saveAccount">Lưu</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { ntripUserApi, onlineUserApi } from '../../services/api';

const loading = ref(false);
const saving = ref(false);
const togglingId = ref<string | number | null>(null);
const accounts = ref<any[]>([]);
const total = ref(0);
const dialogVisible = ref(false);
const editingId = ref<string | number | null>(null);
const dateRange = ref<[Date, Date] | null>(null);
const onlineUserNames = ref<Set<string>>(new Set());

const pageSizes = [
  { label: '10', value: 10 }, { label: '20', value: 20 }, { label: '50', value: 50 },
  { label: '100', value: 100 }, { label: 'Tất cả', value: 9999 },
];
const filters = reactive({ page: 1, size: 20, keywords: '', enabled: undefined as number | undefined });
const onPageSizeChange = () => { filters.page = 1; fetchData(); };

const form = reactive({
  name: '',
  userPwd: '',
  numOnline: 1,
  enabled: 0,
  startTime: undefined as number | undefined,
  endTime: undefined as number | undefined,
});

const formatDate = (ts: number) => {
  if (!ts) return '—';
  return new Date(ts).toLocaleString('vi-VN');
};
const isExpired = (ts: number) => ts && ts < Date.now();

const fetchOnlineUsers = async () => {
  try {
    const res = await onlineUserApi.getOnlineUsers({ page: 1, size: 9999 });
    const records = res.data?.records || res.data || [];
    const names = new Set<string>();
    if (Array.isArray(records)) {
      for (const u of records) {
        if (u.userName || u.name) names.add(u.userName || u.name);
      }
    }
    onlineUserNames.value = names;
  } catch {
    onlineUserNames.value = new Set();
  }
};

const fetchData = async () => {
  loading.value = true;
  try {
    const res = await ntripUserApi.list(filters);
    accounts.value = res.data?.records || [];
    total.value = res.data?.total || 0;
  } catch (e: any) {
    ElMessage.error('Không thể tải danh sách: ' + (e.response?.data?.message || e.message));
  } finally {
    loading.value = false;
  }
};

const openCreateDialog = () => {
  editingId.value = null;
  form.name = '';
  form.userPwd = '';
  form.numOnline = 1;
  form.enabled = 0;
  form.startTime = undefined;
  form.endTime = undefined;
  dateRange.value = null;
  dialogVisible.value = true;
};

const openEditDialog = (row: any) => {
  editingId.value = row.id;
  form.name = row.name;
  form.userPwd = '';
  form.numOnline = row.numOnline || 1;
  form.enabled = row.enabled;
  form.startTime = row.startTime;
  form.endTime = row.endTime;
  dateRange.value = row.startTime && row.endTime
    ? [new Date(row.startTime), new Date(row.endTime)]
    : null;
  dialogVisible.value = true;
};

const saveAccount = async () => {
  if (!form.name || (!form.userPwd && !editingId.value)) {
    ElMessage.warning('Vui lòng nhập đầy đủ tên và mật khẩu');
    return;
  }

  const payload: any = {
    name: form.name,
    numOnline: form.numOnline,
    enabled: form.enabled,
  };
  if (form.userPwd) payload.userPwd = form.userPwd;
  if (dateRange.value) {
    payload.startTime = dateRange.value[0].getTime();
    payload.endTime = dateRange.value[1].getTime();
  }

  saving.value = true;
  try {
    if (editingId.value) {
      await ntripUserApi.update(editingId.value, payload);
      ElMessage.success('Đã cập nhật tài khoản NTRIP');
    } else {
      await ntripUserApi.create(payload);
      ElMessage.success('Đã tạo tài khoản NTRIP mới');
    }
    dialogVisible.value = false;
    fetchData();
  } catch (e: any) {
    ElMessage.error(e.response?.data?.message || 'Lỗi khi lưu');
  } finally {
    saving.value = false;
  }
};

const toggleEnabled = async (row: any, enabled: number) => {
  const action = enabled === 1 ? 'kích hoạt' : 'vô hiệu hóa';
  try {
    await ElMessageBox.confirm(`Bạn muốn ${action} tài khoản "${row.name}"?`, 'Xác nhận');
    togglingId.value = row.id;
    await ntripUserApi.toggle(row.id, enabled);
    ElMessage.success(`Đã ${action} tài khoản ${row.name}`);
    fetchData();
  } catch (err: any) {
    if (err !== 'cancel') {
      console.error('Toggle error:', err);
      ElMessage.error('Lỗi khi cập nhật: ' + (err.response?.data?.message || err.message));
    }
  } finally {
    togglingId.value = null;
  }
};

const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(`Xóa tài khoản "${row.name}"? Hành động này không thể hoàn tác.`, 'Cảnh báo', { type: 'warning' });
    await ntripUserApi.delete([row.id]);
    ElMessage.success('Đã xóa tài khoản');
    fetchData();
  } catch { /* cancelled */ }
};

onMounted(async () => {
  await Promise.all([fetchData(), fetchOnlineUsers()]);
});
</script>
