<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { ElMessage } from 'element-plus';
import { governmentApi } from '../../services/api';
import { VideoPause, InfoFilled } from '@element-plus/icons-vue';

import MapComponent from '../../components/MapComponent.vue';

const loading = ref(false);
const stations = ref<any[]>([]);
const viewMode = ref('list'); // 'list' or 'map'

// Station detail drawer
const drawerVisible = ref(false);
const selectedStation = ref<any>(null);

// Ticket dialog
const ticketDialogVisible = ref(false);
const ticketLoading = ref(false);
const currentStation = ref<any>(null);
const ticketForm = ref({
  subject: '',
  reason: '',
});

const fetchData = async () => {
  loading.value = true;
  try {
    const res = await governmentApi.getStations();
    stations.value = res.data || [];
  } catch (e: any) {
    ElMessage.error('Lỗi tải trạm: ' + (e.response?.data?.message || e.message));
  } finally {
    loading.value = false;
  }
};

const openStationDetails = (station: any) => {
  selectedStation.value = station;
  drawerVisible.value = true;
};

const openTicketDialog = (station: any) => {
  currentStation.value = station;
  ticketForm.value = {
    subject: `Yêu cầu tạm dừng trạm ${station.stationName}`,
    reason: '',
  };
  ticketDialogVisible.value = true;
};

const submitTicket = async () => {
  if (!ticketForm.value.reason) {
    return ElMessage.warning('Vui lòng nhập lý do yêu cầu');
  }

  ticketLoading.value = true;
  try {
    await governmentApi.createTicket({
      subject: ticketForm.value.subject,
      reason: ticketForm.value.reason,
      stationId: currentStation.value.id,
      type: 'STATION_SHUTDOWN'
    });
    ElMessage.success('Đã gửi yêu cầu xử lý trạm');
    ticketDialogVisible.value = false;
  } catch (e: any) {
    ElMessage.error('Lỗi gửi yêu cầu: ' + (e.response?.data?.message || e.message));
  } finally {
    ticketLoading.value = false;
  }
};

onMounted(fetchData);
</script>

<template>
  <div class="gov-stations">
    <div class="flex justify-between items-center mb-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Giám sát trạm CORS</h2>
        <p class="text-gray-500">Danh sách các trạm trong khu vực quản lý.</p>
      </div>
      <div class="flex gap-2">
        <el-radio-group v-model="viewMode" size="large">
          <el-radio-button label="list">📑 Danh sách</el-radio-button>
          <el-radio-button label="map">🗺️ Bản đồ</el-radio-button>
        </el-radio-group>
        <el-button type="primary" color="#10b981" @click="fetchData" :loading="loading">
          Làm mới
        </el-button>
      </div>
    </div>

    <!-- List View -->
    <div v-if="viewMode === 'list'" class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <el-table :data="stations" stripe v-loading="loading" style="width: 100%">
        <el-table-column prop="stationName" label="Tên Trạm" min-width="150" />
        <el-table-column label="Trạng thái" width="130">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? 'Hoạt động' : 'Dừng' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="province" label="Tỉnh/Thành" width="150" />
        <el-table-column prop="identificationName" label="Định danh" width="150" />
        <el-table-column label="Tọa độ" width="220">
          <template #default="{ row }">
            <span class="text-xs text-gray-500">Lat: {{ row.lat?.toFixed(6) }}, Lng: {{ row.lng?.toFixed(6) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="Thao tác" width="180" fixed="right">
          <template #default="{ row }">
            <div class="flex gap-2">
              <el-button type="primary" size="small" plain @click="openStationDetails(row)">
                <el-icon class="mr-1"><InfoFilled /></el-icon> Chi tiết
              </el-button>
              <el-button type="danger" size="small" plain @click="openTicketDialog(row)">
                <el-icon class="mr-1"><VideoPause /></el-icon> Yêu cầu tắt
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- Map View -->
    <div v-else class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <MapComponent 
        :stations="stations" 
        height="calc(100vh - 240px)" 
        @station-click="openStationDetails"
      />
    </div>

    <!-- Station Details Drawer -->
    <el-drawer
      v-model="drawerVisible"
      :title="selectedStation?.stationName || 'Chi tiết trạm'"
      size="450px"
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
        <div class="grid grid-cols-1 gap-y-4">
          <div class="border-b pb-3">
            <div class="text-xs text-gray-400 uppercase tracking-wider mb-1">Khu vực quản lý</div>
            <div class="font-medium text-gray-800">{{ selectedStation.province || '—' }}</div>
          </div>
          <div class="border-b pb-3">
            <div class="text-xs text-gray-400 uppercase tracking-wider mb-1">Tên hiển thị</div>
            <div class="font-medium text-gray-800">{{ selectedStation.identificationName || '—' }}</div>
          </div>
          <div class="border-b pb-3">
            <div class="text-xs text-gray-400 uppercase tracking-wider mb-1">Mã Trạm</div>
            <div class="font-medium text-gray-800 font-mono text-sm">{{ selectedStation.id }}</div>
          </div>
          <div class="border-b pb-3">
            <div class="text-xs text-gray-400 uppercase tracking-wider mb-1">Tọa độ địa lý</div>
            <div class="font-medium text-gray-800">
              <span class="text-gray-500 mr-2 text-xs">Lat:</span> {{ selectedStation.lat?.toFixed(6) || '—' }}<br/>
              <span class="text-gray-500 mr-2 text-xs">Lng:</span> {{ selectedStation.lng?.toFixed(6) || '—' }}
            </div>
          </div>
          <div class="border-b pb-3" v-if="selectedStation.receiverType">
            <div class="text-xs text-gray-400 uppercase tracking-wider mb-1">Receiver</div>
            <div class="font-medium text-gray-800 text-sm">{{ selectedStation.receiverType }}</div>
          </div>
        </div>

        <!-- Actions -->
        <div class="mt-4">
          <el-button type="danger" style="width: 100%" size="large" @click="openTicketDialog(selectedStation)">
            <el-icon class="mr-2"><VideoPause /></el-icon> Gửi yêu cầu dừng hoạt động
          </el-button>
        </div>
      </div>
    </el-drawer>

    <!-- Ticket Dialog -->
    <el-dialog v-model="ticketDialogVisible" :title="'Yêu cầu dừng trạm: ' + currentStation?.stationName" width="500px">
      <el-form :model="ticketForm" label-position="top">
        <el-form-item label="Tiêu đề yêu cầu">
          <el-input v-model="ticketForm.subject" disabled />
        </el-form-item>
        <el-form-item label="Lý do yêu cầu" required>
          <el-input v-model="ticketForm.reason" type="textarea" :rows="4" placeholder="Nhập lý do chi tiết..." />
        </el-form-item>
        <div class="bg-amber-50 p-3 rounded border border-amber-100 mt-4">
          <p class="text-xs text-amber-700 flex items-start">
            <el-icon class="mt-0.5 mr-1"><InfoFilled /></el-icon>
            Yêu cầu này sẽ được gửi đến Quản trị viên hệ thống (Admin/Kỹ thuật) để phê duyệt trước khi thực hiện.
          </p>
        </div>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="ticketDialogVisible = false">Hủy</el-button>
          <el-button type="danger" @click="submitTicket" :loading="ticketLoading">
            Gửi yêu cầu
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
:deep(.el-table) {
  --el-table-header-bg-color: #f8fafc;
  --el-table-header-text-color: #475569;
}
</style>
