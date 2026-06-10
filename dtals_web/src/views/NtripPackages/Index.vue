<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold">Quản lý Gói Thuê Bao NTRIP</h2>
      <el-button type="primary" @click="showAddDialog = true">+ Thêm gói cước</el-button>
    </div>

    <!-- Package Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
      <el-card v-for="pkg in packages" :key="pkg.id" shadow="hover" class="!border-none !rounded-xl">
        <div class="flex flex-col gap-3">
          <div class="flex justify-between items-start">
            <div>
              <div class="text-lg font-bold">{{ pkg.name }}</div>
              <div class="text-sm text-gray-500">{{ pkg.duration }} {{ unitLabel(pkg.durationUnit) }}</div>
            </div>
            <el-tag :type="pkg.active ? 'success' : 'info'" size="small">
              {{ pkg.active ? 'Đang bán' : 'Ngưng' }}
            </el-tag>
          </div>
          <div class="text-2xl font-bold text-blue-600">{{ formatPrice(pkg.price) }}</div>
          <div class="text-sm text-gray-400">{{ pkg.description }}</div>
          <div class="flex justify-between items-center mt-2 pt-3 border-t border-gray-100 dark:border-gray-700">
            <span class="text-xs text-gray-500">{{ pkg.subscriberCount }} thuê bao</span>
            <div class="flex gap-2">
              <el-button size="small" type="primary" plain @click="editPackage(pkg)">Sửa</el-button>
              <el-button size="small" type="danger" plain @click="deletePackage(pkg.id)">Xóa</el-button>
            </div>
          </div>
        </div>
      </el-card>
    </div>

    <!-- NTRIP Account Subscriptions Table -->
    <el-card shadow="hover" class="!border-none !rounded-xl">
      <template #header>
        <div class="flex justify-between items-center">
          <span class="font-semibold">Lịch sử Cấp phát Gói cho Tài khoản NTRIP</span>
          <el-input v-model="searchQuery" placeholder="Tìm kiếm..." class="!w-64" clearable />
        </div>
      </template>
      <el-table :data="filteredSubscriptions" stripe border>
        <el-table-column type="selection" width="55" />
        <el-table-column prop="ntripAccount" label="Tài khoản NTRIP" width="180" />
        <el-table-column prop="userName" label="Chủ sở hữu" width="180" />
        <el-table-column prop="packageName" label="Gói cước" width="150" />
        <el-table-column prop="startDate" label="Ngày kích hoạt" width="140" />
        <el-table-column prop="endDate" label="Ngày hết hạn" width="140" />
        <el-table-column prop="casterStatus" label="Đồng bộ Caster" width="150">
          <template #default="{ row }">
            <el-tag :type="row.casterStatus === 'synced' ? 'success' : row.casterStatus === 'error' ? 'danger' : 'warning'" size="small">
              {{ row.casterStatus === 'synced' ? '✅ Đã đồng bộ' : row.casterStatus === 'error' ? '❌ Lỗi' : '⏳ Chờ xử lý' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Thao tác" width="120" align="center">
          <template #default="{ row }">
            <el-button v-if="row.casterStatus === 'error'" size="small" type="warning" plain @click="retrySync(row)">
              Thử lại
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="mt-4 flex justify-end">
        <el-pagination background layout="prev, pager, next" :total="50" />
      </div>
    </el-card>

    <!-- Add/Edit Package Dialog -->
    <el-dialog v-model="showAddDialog" :title="editingPackage ? 'Sửa gói cước' : 'Thêm gói cước mới'" width="500px">
      <el-form :model="packageForm" label-position="top">
        <el-form-item label="Tên gói">
          <el-input v-model="packageForm.name" placeholder="VD: Gói Cơ bản 1 tháng" />
        </el-form-item>
        <el-form-item label="Thời hạn">
          <div class="flex gap-2 items-center w-full">
            <el-input-number v-model="packageForm.duration" :min="1" :max="365" class="flex-1" />
            <el-select v-model="packageForm.durationUnit" class="!w-32">
              <el-option label="Ngày" value="day" />
              <el-option label="Tháng" value="month" />
              <el-option label="Năm" value="year" />
            </el-select>
          </div>
        </el-form-item>
        <el-form-item label="Giá (VNĐ)">
          <el-input-number v-model="packageForm.price" :min="0" :step="50000" />
        </el-form-item>
        <el-form-item label="Mô tả">
          <el-input v-model="packageForm.description" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="Trạng thái">
          <el-switch v-model="packageForm.active" active-text="Đang bán" inactive-text="Ngưng bán" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddDialog = false">Hủy</el-button>
        <el-button type="primary" @click="savePackage">Lưu</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { packageApi } from '../../services/api';

interface Package {
  id: number;
  name: string;
  duration: number;
  durationUnit: string;
  price: number;
  description: string;
  active: boolean;
  subscriberCount: number;
}

const showAddDialog = ref(false);
const editingPackage = ref<Package | null>(null);
const searchQuery = ref('');
const loading = ref(false);

const packageForm = ref({
  name: '',
  duration: 1,
  durationUnit: 'month',
  price: 500000,
  description: '',
  active: true,
});

const packages = ref<Package[]>([]);

const subscriptions = ref<any[]>([]);

const filteredSubscriptions = computed(() => {
  if (!searchQuery.value) return subscriptions.value;
  const q = searchQuery.value.toLowerCase();
  return subscriptions.value.filter(s =>
    s.ntripAccount?.toLowerCase().includes(q) ||
    s.userName?.toLowerCase().includes(q) ||
    s.packageName?.toLowerCase().includes(q)
  );
});

onMounted(async () => {
  await loadPackages();
});

const loadPackages = async () => {
  loading.value = true;
  try {
    const res = await packageApi.listAll();
    packages.value = res.data || [];
  } catch {
    ElMessage.error('Không thể tải danh sách gói cước');
  } finally {
    loading.value = false;
  }
};

const formatPrice = (price: number) => {
  if (price === 0) return 'Miễn phí';
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
};

const editPackage = (pkg: Package) => {
  editingPackage.value = pkg;
  packageForm.value = { name: pkg.name, duration: pkg.duration, durationUnit: (pkg as any).durationUnit || 'month', price: pkg.price, description: pkg.description, active: pkg.active };
  showAddDialog.value = true;
};

const deletePackage = (id: number) => {
  ElMessageBox.confirm('Bạn có chắc chắn muốn xóa gói cước này?', 'Xác nhận', {
    confirmButtonText: 'Xóa',
    cancelButtonText: 'Hủy',
    type: 'warning',
  }).then(async () => {
    try {
      await packageApi.delete(id);
      ElMessage.success('Đã xóa gói cước');
      await loadPackages();
    } catch {
      ElMessage.error('Không thể xóa gói cước');
    }
  }).catch(() => {});
};

const savePackage = async () => {
  try {
    if (editingPackage.value) {
      await packageApi.update(editingPackage.value.id, packageForm.value);
      ElMessage.success('Đã cập nhật gói cước');
    } else {
      await packageApi.create(packageForm.value);
      ElMessage.success('Đã tạo gói cước mới');
    }
    showAddDialog.value = false;
    editingPackage.value = null;
    packageForm.value = { name: '', duration: 1, durationUnit: 'month', price: 500000, description: '', active: true };
    await loadPackages();
  } catch {
    ElMessage.error('Không thể lưu gói cước');
  }
};

const unitLabel = (unit: string) => {
  const map: Record<string, string> = { day: 'ngày', month: 'tháng', year: 'năm' };
  return map[unit] || 'tháng';
};

const retrySync = (row: any) => {
  ElMessage.info(`Đang thử đồng bộ lại ${row.ntripAccount} lên Caster...`);
  setTimeout(() => {
    row.casterStatus = 'synced';
    ElMessage.success(`Đã đồng bộ thành công ${row.ntripAccount}`);
  }, 1500);
};
</script>
