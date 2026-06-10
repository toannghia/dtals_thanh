<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold text-gray-700">Danh sách Trạm CORS</h2>
      <el-button type="primary" @click="$router.push('/stations/map')">🗺️ Xem bản đồ</el-button>
    </div>

    <!-- Filters -->
    <div class="lte-card mb-4">
      <div class="lte-card-body flex gap-4 flex-wrap items-end">
        <el-input v-model="filters.stationName" placeholder="Tên trạm..." class="!w-56" clearable />
        <el-select v-model="filters.status" placeholder="Trạng thái" clearable class="!w-36">
          <el-option label="Đang chạy" :value="1" />
          <el-option label="Dừng" :value="0" />
        </el-select>
        <el-select v-model="filters.connectStatus" placeholder="Kết nối" clearable class="!w-36">
          <el-option label="Online" :value="1" />
          <el-option label="No data" :value="2" />
          <el-option label="Offline" :value="3" />
        </el-select>
        <el-button type="primary" @click="fetchData">Tìm kiếm</el-button>
      </div>
    </div>

    <!-- Table -->
    <div class="lte-card">
      <div class="lte-card-header flex justify-between">
        <span>Trạm CORS</span>
        <el-tag type="info" size="small">Tổng: {{ total }}</el-tag>
      </div>
      <div class="lte-card-body">
        <el-table :data="stations" stripe border v-loading="loading">
          <el-table-column prop="id" label="ID" width="70" />
          <el-table-column prop="stationName" label="Tên Trạm" min-width="180" />
          <el-table-column label="Trạng thái" width="130">
            <template #default="{ row }">
              <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
                {{ row.status === 1 ? 'Đang chạy' : 'Dừng' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="identificationName" label="Tên hiển thị" min-width="150" />
          <el-table-column prop="lat" label="Lat" width="130">
            <template #default="{ row }">{{ row.lat?.toFixed(6) }}</template>
          </el-table-column>
          <el-table-column prop="lng" label="Lng" width="130">
            <template #default="{ row }">{{ row.lng?.toFixed(6) }}</template>
          </el-table-column>
          <el-table-column prop="receiverType" label="Receiver" min-width="120" />
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
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { ElMessage } from 'element-plus';
import { stationApi } from '../../services/api';

const loading = ref(false);
const stations = ref<any[]>([]);
const total = ref(0);
const pageSizes = [
  { label: '10', value: 10 }, { label: '20', value: 20 }, { label: '50', value: 50 },
  { label: '100', value: 100 }, { label: 'Tất cả', value: 9999 },
];
const filters = reactive({ page: 1, size: 20, stationName: '', status: undefined as number | undefined, connectStatus: undefined as number | undefined });
const onPageSizeChange = () => { filters.page = 1; fetchData(); };

const fetchData = async () => {
  loading.value = true;
  try {
    const res = await stationApi.getStations(filters);
    // API returns: { total, page, size, records: [...] }
    stations.value = res.data?.records || [];
    total.value = res.data?.total || 0;
  } catch (e: any) {
    ElMessage.error('Lỗi tải trạm: ' + (e.response?.data?.message || e.message));
  } finally {
    loading.value = false;
  }
};

onMounted(fetchData);
</script>
