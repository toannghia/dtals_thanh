<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold">Thanh toán nhiều Tài khoản NTRIP</h2>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left: Account List with Checkboxes -->
      <div class="lg:col-span-2">
        <el-card shadow="hover" class="!border-none !rounded-xl">
          <template #header>
            <div class="flex justify-between items-center">
              <span class="font-semibold">Chọn tài khoản NTRIP cần gia hạn</span>
              <el-checkbox v-model="selectAll" @change="toggleSelectAll" label="Chọn tất cả" />
            </div>
          </template>
          <el-table :data="ntripAccounts" stripe border @selection-change="handleSelectionChange" ref="tableRef">
            <el-table-column type="selection" width="55" />
            <el-table-column prop="ntripId" label="Tài khoản NTRIP" width="180" />
            <el-table-column prop="device" label="Tên thiết bị" />
            <el-table-column prop="currentExpiry" label="Hết hạn hiện tại" width="150">
              <template #default="{ row }">
                <el-tag :type="isExpired(row.currentExpiry) ? 'danger' : 'success'" size="small">
                  {{ row.currentExpiry }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="Gói gia hạn" width="200">
              <template #default="{ row }">
                <el-select v-model="row.selectedPackage" placeholder="Chọn gói" size="small">
                  <el-option
                    v-for="pkg in availablePackages"
                    :key="pkg.id"
                    :label="`${pkg.name} - ${formatPrice(pkg.price)}`"
                    :value="pkg.id"
                  />
                </el-select>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </div>

      <!-- Right: Summary -->
      <div>
        <el-card shadow="hover" class="!border-none !rounded-xl sticky top-6">
          <template #header>
            <span class="font-semibold">Tổng hợp đơn hàng</span>
          </template>
          <div class="space-y-3">
            <div v-if="selectedAccounts.length === 0" class="text-gray-400 text-center py-8">
              Chưa chọn tài khoản nào
            </div>
            <div v-for="acc in selectedAccounts" :key="acc.ntripId"
              class="flex justify-between items-center py-2 border-b border-gray-100 dark:border-gray-700">
              <div>
                <div class="text-sm font-medium">{{ acc.ntripId }}</div>
                <div class="text-xs text-gray-400">{{ getPackageName(acc.selectedPackage) }}</div>
              </div>
              <div class="text-sm font-bold text-blue-600">{{ formatPrice(getPackagePrice(acc.selectedPackage)) }}</div>
            </div>
            <div class="pt-4 border-t-2 border-gray-200 dark:border-gray-600">
              <div class="flex justify-between items-center">
                <span class="text-lg font-bold">Tổng cộng</span>
                <span class="text-xl font-bold text-green-600">{{ formatPrice(totalPrice) }}</span>
              </div>
            </div>
            <el-button type="primary" class="w-full !mt-4" size="large"
              :disabled="selectedAccounts.length === 0"
              @click="handleCheckout">
              Thanh toán {{ selectedAccounts.length }} tài khoản
            </el-button>
          </div>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { ElMessage } from 'element-plus';

interface NtripAccount {
  ntripId: string;
  device: string;
  currentExpiry: string;
  selectedPackage: number | null;
}

const selectAll = ref(false);
const selectedAccounts = ref<NtripAccount[]>([]);

const availablePackages = [
  { id: 1, name: 'Gói Cơ bản (1T)', price: 500000 },
  { id: 2, name: 'Gói Tiêu chuẩn (6T)', price: 2500000 },
  { id: 3, name: 'Gói Chuyên nghiệp (12T)', price: 4500000 },
];

const ntripAccounts = ref<NtripAccount[]>([
  { ntripId: 'NTRIP-HN001', device: 'Rover RTK #1', currentExpiry: '2026-03-15', selectedPackage: 1 },
  { ntripId: 'NTRIP-HN002', device: 'Rover RTK #2', currentExpiry: '2026-02-10', selectedPackage: 1 },
  { ntripId: 'NTRIP-HN003', device: 'Base Station A', currentExpiry: '2026-04-01', selectedPackage: 2 },
  { ntripId: 'NTRIP-HCM001', device: 'Drone RTK #1', currentExpiry: '2026-01-20', selectedPackage: 1 },
]);

const isExpired = (date: string) => new Date(date) < new Date();

const formatPrice = (price: number) => {
  if (price === 0) return 'Miễn phí';
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
};

const getPackageName = (id: number | null) => availablePackages.find(p => p.id === id)?.name ?? '—';
const getPackagePrice = (id: number | null) => availablePackages.find(p => p.id === id)?.price ?? 0;

const totalPrice = computed(() =>
  selectedAccounts.value.reduce((sum, acc) => sum + getPackagePrice(acc.selectedPackage), 0)
);

const handleSelectionChange = (selected: NtripAccount[]) => {
  selectedAccounts.value = selected;
  selectAll.value = selected.length === ntripAccounts.value.length;
};

const toggleSelectAll = (val: boolean) => {
  // Element Plus table selection is managed via ref, simplified here
  selectedAccounts.value = val ? [...ntripAccounts.value] : [];
};

const handleCheckout = () => {
  ElMessage.success(`Đã tạo đơn thanh toán ${selectedAccounts.value.length} tài khoản — Tổng: ${formatPrice(totalPrice.value)}`);
};
</script>
