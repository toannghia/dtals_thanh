<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { governmentApi } from '../../services/api';
import { Monitor, Connection, WarnTriangleFilled, List } from '@element-plus/icons-vue';
import MapComponent from '../../components/MapComponent.vue';
import { useAuthStore } from '../../store/auth';

const authStore = useAuthStore();
const stats = ref({
  totalStations: 0,
  activeStations: 0,
  inactiveStations: 0,
  pendingTickets: 0
});
const stations = ref<any[]>([]);
const loading = ref(true);
const selectedProvince = ref('');

// Station detail drawer
const drawerVisible = ref(false);
const selectedStation = ref<any>(null);

const openStationDetails = (station: any) => {
  selectedStation.value = station;
  drawerVisible.value = true;
};

onMounted(async () => {
  try {
    const [statsRes, stationsRes] = await Promise.all([
      governmentApi.getDashboard(),
      governmentApi.getStations()
    ]);
    stats.value = statsRes.data;
    stations.value = stationsRes.data || [];
    
    // Auto focus on the first assigned province
    const assigned = (authStore.user as any)?.assignedProvinces || [];
    if (assigned.length > 0 && assigned[0] !== 'ALL') {
      selectedProvince.value = assigned[0];
    }
  } catch (error) {
    console.error('Failed to fetch dashboard data', error);
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div class="government-dashboard">
    <div class="flex justify-between items-center mb-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Tổng quan khu vực quản lý</h2>
        <p class="text-gray-500">Thống kê hiện trạng trạm CORS và yêu cầu xử lý trong địa bàn.</p>
      </div>
      <div v-if="selectedProvince" class="bg-emerald-50 px-4 py-2 rounded-lg border border-emerald-100">
        <span class="text-emerald-700 font-medium">📍 Khu vực: {{ selectedProvince }}</span>
      </div>
    </div>

    <el-row :gutter="20" v-loading="loading">
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="flex items-center">
            <div class="icon-box bg-blue-100 text-blue-600">
              <el-icon><Monitor /></el-icon>
            </div>
            <div class="ml-4">
              <div class="text-sm text-gray-500 uppercase tracking-wider">Tổng số trạm</div>
              <div class="text-2xl font-bold">{{ stats.totalStations }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="flex items-center">
            <div class="icon-box bg-emerald-100 text-emerald-600">
              <el-icon><Connection /></el-icon>
            </div>
            <div class="ml-4">
              <div class="text-sm text-gray-500 uppercase tracking-wider">Trạm hoạt động</div>
              <div class="text-2xl font-bold">{{ stats.activeStations }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="flex items-center">
            <div class="icon-box bg-rose-100 text-rose-600">
              <el-icon><WarnTriangleFilled /></el-icon>
            </div>
            <div class="ml-4">
              <div class="text-sm text-gray-500 uppercase tracking-wider">Trạm mất kết nối</div>
              <div class="text-2xl font-bold">{{ stats.inactiveStations }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="flex items-center">
            <div class="icon-box bg-amber-100 text-amber-600">
              <el-icon><List /></el-icon>
            </div>
            <div class="ml-4">
              <div class="text-sm text-gray-500 uppercase tracking-wider">Yêu cầu chờ duyệt</div>
              <div class="text-2xl font-bold">{{ stats.pendingTickets }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Map Section -->
    <div class="mt-6 bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="p-4 border-b border-gray-50 flex justify-between items-center">
        <h3 class="font-bold text-gray-700 flex items-center">
          <el-icon class="mr-2 text-emerald-500"><Monitor /></el-icon>
          Bản đồ hiện trạng mạng lưới trạm
        </h3>
        <el-button type="primary" link @click="$router.push('/gov/stations')">
          Xem chi tiết danh sách <el-icon class="ml-1"><List /></el-icon>
        </el-button>
      </div>
      <div class="relative">
        <MapComponent 
          :stations="stations" 
          :selected-province="selectedProvince"
          height="500px" 
          @station-click="openStationDetails"
        />
        <div v-if="loading" class="absolute inset-0 bg-white/50 flex items-center justify-center z-[1000]">
          <el-icon class="is-loading" :size="32"><Connection /></el-icon>
        </div>
      </div>
    </div>

    <!-- Station Details Drawer -->
    <el-drawer
      v-model="drawerVisible"
      :title="selectedStation?.stationName || 'Chi tiết trạm'"
      size="400px"
      append-to-body
      destroy-on-close
    >
      <div v-if="selectedStation" class="flex flex-col gap-6">
        <!-- Status Header -->
        <div class="flex items-center gap-4 p-4 rounded-lg" :class="selectedStation.status === 1 ? 'bg-emerald-50' : 'bg-red-50'">
          <div class="w-12 h-12 rounded-full flex items-center justify-center text-white text-xl shadow-sm"
               :class="selectedStation.status === 1 ? 'bg-emerald-500' : 'bg-red-500'">
            📡
          </div>
          <div>
            <h3 class="font-bold text-lg text-gray-800">{{ selectedStation.stationName }}</h3>
            <div class="text-sm font-medium" :class="selectedStation.status === 1 ? 'text-emerald-600' : 'text-red-600'">
              {{ selectedStation.status === 1 ? '🟢 Đang hoạt động' : '🔴 Dừng hoạt động' }}
            </div>
          </div>
        </div>

        <!-- Details Grid -->
        <div class="grid grid-cols-1 gap-y-4 px-2">
          <div class="border-b pb-3">
            <div class="text-xs text-gray-400 uppercase tracking-wider mb-1">Tỉnh/Thành</div>
            <div class="font-medium text-gray-800">{{ selectedStation.province || '—' }}</div>
          </div>
          <div class="border-b pb-3">
            <div class="text-xs text-gray-400 uppercase tracking-wider mb-1">Tọa độ địa lý</div>
            <div class="font-medium text-gray-800">
              <span class="text-gray-500 mr-2 text-xs">Lat:</span> {{ selectedStation.lat?.toFixed(6) || '—' }}<br/>
              <span class="text-gray-500 mr-2 text-xs">Lng:</span> {{ selectedStation.lng?.toFixed(6) || '—' }}
            </div>
          </div>
        </div>

        <div class="mt-4 px-2">
          <el-button type="primary" plain @click="$router.push('/gov/stations')" class="w-full">
            Quản lý trạm này
          </el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<style scoped>
.stat-card {
  border-radius: 12px;
  border: none;
  transition: all 0.3s;
}
.stat-card:hover {
  transform: translateY(-4px);
}
.icon-box {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}
</style>
