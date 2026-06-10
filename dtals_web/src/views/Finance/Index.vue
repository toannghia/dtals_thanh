<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold">Đối soát Tài chính & Giao dịch</h2>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <el-card shadow="hover" class="!border-none !rounded-xl">
        <div class="text-sm text-gray-500">Tổng thu tháng</div>
        <div class="text-2xl font-bold text-green-600">245,000,000₫</div>
      </el-card>
      <el-card shadow="hover" class="!border-none !rounded-xl">
        <div class="text-sm text-gray-500">Giao dịch thành công</div>
        <div class="text-2xl font-bold text-blue-600">342</div>
      </el-card>
      <el-card shadow="hover" class="!border-none !rounded-xl">
        <div class="text-sm text-gray-500">Cần xử lý ngoại lệ</div>
        <div class="text-2xl font-bold text-red-500">5</div>
      </el-card>
      <el-card shadow="hover" class="!border-none !rounded-xl">
        <div class="text-sm text-gray-500">Chờ đối soát</div>
        <div class="text-2xl font-bold text-amber-500">12</div>
      </el-card>
    </div>

    <!-- Transactions Table -->
    <el-card shadow="hover" class="!border-none !rounded-xl">
      <template #header>
        <div class="flex justify-between items-center">
          <span class="font-semibold">Lịch sử Giao dịch VietQR</span>
          <div class="flex gap-3">
            <el-date-picker v-model="dateRange" type="daterange" range-separator="—"
              start-placeholder="Từ ngày" end-placeholder="Đến ngày" size="default" />
            <el-select v-model="filterStatus" placeholder="Trạng thái" clearable class="!w-40">
              <el-option label="Thành công" value="success" />
              <el-option label="Ngoại lệ" value="exception" />
              <el-option label="Chờ đối soát" value="pending" />
            </el-select>
          </div>
        </div>
      </template>
      <el-table :data="filteredTransactions" stripe border>
        <el-table-column prop="id" label="Mã GD" width="130" />
        <el-table-column prop="time" label="Thời gian" width="170" />
        <el-table-column prop="sender" label="Người chuyển" width="180" />
        <el-table-column prop="content" label="Nội dung CK" />
        <el-table-column prop="amount" label="Số tiền" width="150">
          <template #default="{ row }">
            <span class="font-bold text-green-600">{{ formatPrice(row.amount) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="Trạng thái" width="140">
          <template #default="{ row }">
            <el-tag :type="statusColor(row.status)" size="small">
              {{ statusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Thao tác" width="160" align="center">
          <template #default="{ row }">
            <el-button v-if="row.status === 'exception'" size="small" type="warning" plain @click="handleException(row)">
              Xử lý
            </el-button>
            <el-button v-if="row.status === 'pending'" size="small" type="primary" plain @click="confirmTransaction(row)">
              Duyệt
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="mt-4 flex justify-end">
        <el-pagination background layout="prev, pager, next" :total="100" />
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';

const dateRange = ref<[Date, Date] | null>(null);
const filterStatus = ref('');

const transactions = ref([
  { id: 'TXN-001', time: '2026-02-26 22:30:15', sender: 'Nguyễn Văn A', content: 'DTALS NTRIP-HN001 6T', amount: 2500000, status: 'success' },
  { id: 'TXN-002', time: '2026-02-26 22:15:00', sender: 'Trần Thị B', content: 'DTALS THANH TOAN', amount: 500000, status: 'exception' },
  { id: 'TXN-003', time: '2026-02-26 21:50:00', sender: 'Lê Văn C', content: 'DTALS NTRIP-HCM001 NTRIP-HCM002 NTRIP-DN001', amount: 1500000, status: 'success' },
  { id: 'TXN-004', time: '2026-02-26 20:00:00', sender: 'Phạm Văn D', content: 'DTALS NTRIP-HN003 1T', amount: 490000, status: 'pending' },
  { id: 'TXN-005', time: '2026-02-26 19:30:00', sender: 'Hoàng Thị E', content: 'GD SAI NOI DUNG', amount: 300000, status: 'exception' },
]);

const filteredTransactions = computed(() => {
  return transactions.value.filter(t => {
    return !filterStatus.value || t.status === filterStatus.value;
  });
});

const formatPrice = (price: number) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);

const statusColor = (s: string) => s === 'success' ? 'success' : s === 'exception' ? 'danger' : 'warning';
const statusLabel = (s: string) => s === 'success' ? '✅ Thành công' : s === 'exception' ? '⚠️ Ngoại lệ' : '⏳ Chờ duyệt';

const handleException = (row: any) => {
  ElMessageBox.confirm(
    `Giao dịch ${row.id} từ "${row.sender}" — Nội dung CK sai định dạng. Bạn muốn duyệt thủ công?`,
    'Xử lý ngoại lệ', {
      confirmButtonText: 'Duyệt thủ công',
      cancelButtonText: 'Hủy',
      type: 'warning',
    }
  ).then(() => {
    row.status = 'success';
    ElMessage.success(`Đã duyệt thủ công giao dịch ${row.id}`);
  }).catch(() => {});
};

const confirmTransaction = (row: any) => {
  row.status = 'success';
  ElMessage.success(`Đã xác nhận giao dịch ${row.id}`);
};
</script>
