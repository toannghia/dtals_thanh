<template>
  <div>
    <div class="mb-8">
      <h2 class="text-2xl font-bold text-gray-800">Đơn hàng của tôi</h2>
      <p class="text-gray-500">Quản lý và thanh toán các đơn hàng cấp phát tài khoản NTRIP</p>
    </div>

    <el-card shadow="hover" class="!border-none !rounded-xl min-h-[500px]">
      <!-- Filters and Actions -->
      <div class="flex justify-between items-center mb-6">
        <el-radio-group v-model="statusFilter" @change="loadOrders">
          <el-radio-button label="">Tất cả</el-radio-button>
          <el-radio-button label="PENDING">Chờ thanh toán</el-radio-button>
          <el-radio-button label="PAID">Đã thanh toán</el-radio-button>
          <el-radio-button label="CANCELLED">Đã hủy</el-radio-button>
        </el-radio-group>

        <el-button 
          v-if="selectedOrders.length > 0 && statusFilter === 'PENDING'"
          type="primary" 
          size="large" 
          @click="proceedToCheckout"
        >
          Thanh toán {{ selectedOrders.length }} đơn ({{ formatPrice(totalSelectedPrice) }})
        </el-button>
      </div>

      <!-- Orders Table -->
      <el-table 
        v-loading="loading" 
        :data="orders" 
        border 
        stripe 
        row-key="id"
        @selection-change="handleSelectionChange"
      >
        <!-- Only allow selection for PENDING orders -->
        <el-table-column 
          v-if="statusFilter === 'PENDING' || statusFilter === ''"
          type="selection" 
          width="55" 
          :selectable="(row: any) => row.status === 'PENDING'" 
        />
        
        <el-table-column label="Mã đơn" prop="id" width="100" align="center">
          <template #default="{ row }">
            <span class="font-bold text-gray-600">#{{ row.id }}</span>
          </template>
        </el-table-column>
        
        <el-table-column label="Thông tin tài khoản" min-width="250">
          <template #default="{ row }">
            <div class="font-medium text-blue-700 mb-1">{{ row.ntripAccountId }}</div>
            <div class="text-xs text-gray-500">{{ row.packageName }} - {{ row.packageDuration }} tháng</div>
          </template>
        </el-table-column>
        
        <el-table-column label="Số tiền" prop="amount" width="150" align="right">
          <template #default="{ row }">
            <span class="font-bold text-lg" :class="{ 'text-green-600': row.status === 'PAID', 'text-yellow-600': row.status === 'PENDING' }">
              {{ formatPrice(row.amount) }}
            </span>
          </template>
        </el-table-column>
        
        <el-table-column label="Ngày tạo" width="150" align="center">
          <template #default="{ row }">
            <span class="text-sm">{{ formatDate(row.createdAt || new Date()) }}</span>
          </template>
        </el-table-column>
        
        <el-table-column label="Trạng thái" width="150" align="center">
          <template #default="{ row }">
             <el-tag :type="getStatusTag(row.status)">
               {{ getStatusLabel(row.status) }}
             </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column label="Thao tác" width="150" align="center">
          <template #default="{ row }">
            <el-button v-if="row.status === 'PENDING'" size="small" type="primary" plain @click="checkoutSingle(row)">Thanh toán</el-button>
            <el-button v-if="row.status === 'PENDING'" size="small" type="danger" text @click="cancelOrder(row)">Hủy</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="mt-6 flex justify-end">
        <el-pagination background layout="prev, pager, next" :total="total" />
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage, ElMessageBox } from 'element-plus';
import { orderApi } from '../../services/api';

const router = useRouter();
const orders = ref<any[]>([]);
const total = ref(0);
const loading = ref(true);
const statusFilter = ref('PENDING'); // Default to showing pending orders
const selectedOrders = ref<any[]>([]);

onMounted(() => {
  loadOrders();
});

const loadOrders = async () => {
  loading.value = true;
  selectedOrders.value = []; // Reset selection on filter change
  try {
    const params: any = {};
    if (statusFilter.value) {
      params.status = statusFilter.value;
    }
    const res = await orderApi.list(params);
    orders.value = res.data.items || res.data || [];
    total.value = res.data.total || orders.value.length;
  } catch (error) {
    console.error('Không thể tải danh sách đơn hàng', error);
    // Mock Data Fallback
    orders.value = [
      { id: 101, ntripAccountId: 'RtkCORS_01', packageId: 2, packageName: 'Gói Tiêu chuẩn', packageDuration: 6, amount: 2500000, status: 'PENDING', createdAt: new Date() },
      { id: 102, ntripAccountId: 'RtkCORS_02', packageId: 1, packageName: 'Gói Cơ bản', packageDuration: 1, amount: 500000, status: 'PENDING', createdAt: new Date() },
      { id: 100, ntripAccountId: 'RtkDrone_01', packageId: 3, packageName: 'Gói VIP', packageDuration: 12, amount: 4500000, status: 'PAID', createdAt: new Date(Date.now() - 86400000) },
    ].filter(o => !statusFilter.value || o.status === statusFilter.value);
  } finally {
    loading.value = false;
  }
};

const handleSelectionChange = (val: any[]) => {
  selectedOrders.value = val;
};

const totalSelectedPrice = computed(() => {
  return selectedOrders.value.reduce((sum, order) => sum + (order.amount || 0), 0);
});

// Chuyển tới màn hình Checkout tổng hợp với danh sách IDs
const proceedToCheckout = () => {
  const ids = selectedOrders.value.map(o => o.id);
  router.push({ path: '/user/checkout', query: { ids: ids.join(',') } });
};

const checkoutSingle = (row: any) => {
  // Select row programmatic visually if needed, then route
  router.push({ path: '/user/checkout', query: { ids: row.id } });
};

const cancelOrder = (row: any) => {
  ElMessageBox.confirm(`Bạn có chắc muốn hủy đơn hàng #${row.id} trị giá ${formatPrice(row.amount)}?`, 'Xác nhận hủy', {
    confirmButtonText: 'Đồng ý hủy',
    cancelButtonText: 'Quay lại',
    type: 'warning'
  }).then(async () => {
    try {
      await orderApi.cancel(row.id);
      ElMessage.success('Đã hủy đơn hàng');
      await loadOrders();
    } catch (e: any) {
      // Mock logic if backend not ready
      if(e.response?.status !== 200) {
        const idx = orders.value.findIndex(o => o.id === row.id);
        if(idx !== -1) orders.value[idx].status = 'CANCELLED';
        ElMessage.success('Đã hủy đơn hàng (Mock)');
      }
    }
  }).catch(() => {});
};

const formatPrice = (price: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
};

const formatDate = (dateInput: string | Date) => {
  const date = new Date(dateInput);
  return `${date.toLocaleDateString('vi-VN')} ${date.toLocaleTimeString('vi-VN', {hour: '2-digit', minute:'2-digit'})}`;
};

const getStatusTag = (status: string) => {
  switch (status) {
    case 'PAID': return 'success';
    case 'PENDING': return 'warning';
    case 'CANCELLED': return 'info';
    default: return 'info';
  }
};

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'PAID': return 'Đã thanh toán';
    case 'PENDING': return 'Chờ thanh toán';
    case 'CANCELLED': return 'Đã hủy';
    default: return 'Không xác định';
  }
};
</script>
