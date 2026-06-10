<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { adminSupportApi } from '../../../services/api';

const router = useRouter();

const loading = ref(true);
const requests = ref<any[]>([]);
const total = ref(0);
const filters = reactive({ 
  page: 1, 
  limit: 10,
  status: '' 
});

const statusOptions = [
  { label: 'Tất cả', value: '' },
  { label: 'Đang chờ xử lý (PENDING)', value: 'PENDING' },
  { label: 'Đang hỗ trợ (IN_PROGRESS)', value: 'IN_PROGRESS' },
  { label: 'Đã xong (RESOLVED)', value: 'RESOLVED' },
  { label: 'Đã đóng (CLOSED)', value: 'CLOSED' }
];

const fetchRequests = async () => {
  loading.value = true;
  try {
    const params: any = { page: filters.page, limit: filters.limit };
    if (filters.status) params.status = filters.status;
    
    const res = await adminSupportApi.list(params);
    requests.value = res.data.items || [];
    total.value = res.data.total || 0;
  } catch (error: any) {
    ElMessage.error('Lỗi tải danh sách yêu cầu: ' + (error.response?.data?.message || error.message));
  } finally {
    loading.value = false;
  }
};

const onPageChange = (val: number) => {
  filters.page = val;
  fetchRequests();
};

const getStatusTagType = (status: string) => {
  switch (status) {
    case 'PENDING': return 'warning';
    case 'IN_PROGRESS': return 'primary';
    case 'RESOLVED': return 'success';
    case 'CLOSED': return 'info';
    default: return 'info';
  }
};

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'PENDING': return 'Chờ xử lý';
    case 'IN_PROGRESS': return 'Đang xử lý';
    case 'RESOLVED': return 'Đã xong';
    case 'CLOSED': return 'Đã đóng';
    default: return status;
  }
};

onMounted(() => {
  fetchRequests();
});
</script>

<template>
  <div class="admin-support-page">
    <div class="flex justify-between items-center mb-6">
      <div>
        <!--<h2 class="text-2xl font-bold text-gray-800">Quản lý Yêu cầu hỗ trợ</h2>-->
        <p class="text-gray-500">Tiếp nhận và xử lý yêu cầu/sự cố từ người dùng hệ thống.</p>
      </div>
      <div>
        <!-- Additional global actions can go here -->
      </div>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <!-- Filters -->
      <div class="p-4 border-b border-gray-100 bg-gray-50 flex gap-4 items-center">
        <span class="text-sm font-medium text-gray-600">Lọc theo trạng thái:</span>
        <el-select v-model="filters.status" placeholder="Trạng thái" style="width: 250px" @change="() => { filters.page = 1; fetchRequests(); }">
          <el-option
            v-for="item in statusOptions"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select>
        <el-button @click="fetchRequests" :loading="loading">Làm mới</el-button>
      </div>

      <div class="p-0">
        <el-table :data="requests" v-loading="loading" style="width: 100%" row-class-name="cursor-pointer" @row-click="(row: any) => router.push(`/support/${row.id}`)">
          <el-table-column prop="code" label="Mã Y/C" width="120">
            <template #default="{ row }">
              <span class="font-mono text-blue-600 font-medium">{{ row.code }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="user" label="Người yêu cầu" width="200">
            <template #default="{ row }">
              <div v-if="row.user">
                <div class="font-medium text-gray-800">{{ row.user.fullName || row.user.username }}</div>
                <div class="text-xs text-gray-500">{{ row.user.username }}</div>
              </div>
            </template>
          </el-table-column>
          <el-table-column prop="subject" label="Tiêu đề" min-width="250">
            <template #default="{ row }">
              <span class="font-medium text-gray-800">{{ row.subject || row.title }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="updatedAt" label="Cập nhật lần cuối" width="180">
            <template #default="{ row }">
              <span class="text-gray-500">{{ new Date(row.updatedAt).toLocaleString('vi-VN') }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="Trạng thái" width="140" align="center">
            <template #default="{ row }">
              <el-tag :type="getStatusTagType(row.status)" effect="light">
                {{ getStatusLabel(row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="" width="100" align="right">
            <template #default>
              <el-button size="small" type="primary" plain>Xử lý</el-button>
            </template>
          </el-table-column>
        </el-table>

        <div class="p-4 flex justify-end border-t border-gray-100 bg-gray-50" v-if="total > 0">
          <el-pagination
            v-model:current-page="filters.page"
            :page-size="filters.limit"
            :total="total"
            background
            layout="prev, pager, next"
            @current-change="onPageChange"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.admin-support-page {
  animation: fadeIn 0.4s ease-out;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
