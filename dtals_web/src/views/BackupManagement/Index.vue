<template>
  <div class="backup-management">
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold text-gray-700">Quản lý Sao lưu (Backup)</h2>
      <div class="flex gap-2">
        <el-button type="info" plain :icon="Setting" @click="openConfig">Cấu hình tự động</el-button>
        <el-button type="primary" :loading="running" @click="runBackup">Chạy Backup Ngay</el-button>
      </div>
    </div>

    <!-- Table -->
    <div class="lte-card">
      <div class="lte-card-header flex justify-between items-center">
        <span>Lịch sử Sao lưu Hệ thống lên Google Drive</span>
        <el-tag type="info" size="small">Tổng: {{ total }}</el-tag>
      </div>
      <div class="lte-card-body">
        <el-table :data="logs" stripe border v-loading="loading">
          <el-table-column label="STT" width="70" align="center">
            <template #default="{ $index }">
              {{ (filters.page - 1) * filters.limit + $index + 1 }}
            </template>
          </el-table-column>
          
          <el-table-column prop="filename" label="Tên file" min-width="250" />
          
          <el-table-column label="Loại" width="120" align="center">
            <template #default="{ row }">
              <el-tag :type="row.type === 'database' ? 'primary' : 'warning'" size="small">
                {{ row.type === 'database' ? 'Database (SQL)' : 'Files (TGZ)' }}
              </el-tag>
            </template>
          </el-table-column>
          
          <el-table-column label="Kích thước" width="120" align="right">
            <template #default="{ row }">
              {{ formatSize(row.size) }}
            </template>
          </el-table-column>
          
          <el-table-column label="Trạng thái" width="120" align="center">
            <template #default="{ row }">
              <el-tag :type="getStatusType(row.status)" size="small">
                {{ formatStatus(row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          
          <el-table-column label="Thời gian" width="180">
            <template #default="{ row }">
              {{ formatDate(row.createdAt) }}
            </template>
          </el-table-column>
          
          <el-table-column label="Thao tác" width="120" align="center">
            <template #default="{ row }">
              <el-button 
                v-if="row.driveLink" 
                size="small" 
                type="success" 
                plain 
                tag="a" 
                :href="row.driveLink" 
                target="_blank">
                Tải về
              </el-button>
              <span v-else class="text-gray-400 text-sm">-</span>
            </template>
          </el-table-column>
        </el-table>
        
        <div class="mt-4 flex justify-between items-center">
          <div class="flex items-center gap-2 text-sm text-gray-500">
            <span>Hiển thị</span>
            <el-select v-model="filters.limit" class="!w-28" @change="onPageSizeChange">
              <el-option v-for="s in pageSizes" :key="s.value" :label="s.label" :value="s.value" />
            </el-select>
            <span>/ trang</span>
          </div>
          <el-pagination 
            background 
            layout="prev, pager, next, total" 
            :total="total"
            :page-size="filters.limit" 
            v-model:current-page="filters.page" 
            @current-change="fetchData" 
          />
        </div>
      </div>
    </div>

    <!-- Config Dialog -->
    <el-dialog v-model="configDialog.visible" title="Cấu hình hệ thống tự động" width="450px" destroy-on-close>
      <el-form :model="configForm" label-width="140px" v-loading="configDialog.loading">
        <el-form-item label="Giờ chạy hằng ngày">
          <el-time-picker v-model="configForm.time" format="HH:mm" placeholder="Chọn giờ chạy backup" class="!w-full" />
        </el-form-item>
        <el-form-item label="Số ngày lưu tệp">
          <el-input-number v-model="configForm.keepDays" :min="1" :max="90" class="!w-full" />
        </el-form-item>
        <div class="text-xs text-gr-500 text-center text-gray-500 px-4 mt-2">
          Các bản sao lưu trên Google Drive cũ hơn số ngày ở trên sẽ tự động bị dọn dẹp để tiết kiệm dung lượng.
        </div>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="configDialog.visible = false">Hủy</el-button>
          <el-button type="primary" @click="saveConfig" :loading="configDialog.saving">Lưu thay đổi</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Setting } from '@element-plus/icons-vue';
import { backupApi } from '../../services/api';

const loading = ref(false);
const running = ref(false);
const logs = ref<any[]>([]);
const total = ref(0);

// Config State
const configDialog = reactive({ visible: false, loading: false, saving: false });
const configForm = reactive({ time: new Date(2000, 0, 1, 2, 0), keepDays: 7 });

const pageSizes = [
  { label: '10', value: 10 }, { label: '20', value: 20 }, { label: '50', value: 50 },
];
const filters = reactive({ page: 1, limit: 20 });
const onPageSizeChange = () => { filters.page = 1; fetchData(); };

const fetchData = async () => {
  loading.value = true;
  try {
    const res = await backupApi.list({ page: filters.page, limit: filters.limit });
    logs.value = res.data.items || [];
    total.value = res.data.total || 0;
  } catch (e: any) {
    ElMessage.error('Không tải được lịch sử backup: ' + (e.response?.data?.message || e.message));
  } finally {
    loading.value = false;
  }
};

const openConfig = async () => {
  configDialog.visible = true;
  configDialog.loading = true;
  try {
    const res = await backupApi.getConfig();
    const data = res.data;
    // Parse cron "0 2 * * *" -> hours: 2, minutes: 0
    let hours = 2;
    let minutes = 0;
    if (data.cronTime) {
      const parts = data.cronTime.split(' ');
      if (parts.length >= 2) {
        minutes = parseInt(parts[0]) || 0;
        hours = parseInt(parts[1]) || 0;
      }
    }
    configForm.time = new Date(2000, 0, 1, hours, minutes);
    configForm.keepDays = data.keepDays || 7;
  } catch (err: any) {
    ElMessage.error('Lỗi tải cấu hình: ' + err.message);
    configDialog.visible = false;
  } finally {
    configDialog.loading = false;
  }
};

const saveConfig = async () => {
  configDialog.saving = true;
  try {
    const h = configForm.time.getHours();
    const m = configForm.time.getMinutes();
    const cronTime = `${m} ${h} * * *`;
    
    await backupApi.updateConfig({
      cronTime,
      keepDays: configForm.keepDays,
    });
    
    ElMessage.success('Lưu cấu hình thành công! Cronjob đã được cập nhật.');
    configDialog.visible = false;
  } catch (err: any) {
    ElMessage.error('Lỗi khi lưu cấu hình: ' + (err.response?.data?.message || err.message));
  } finally {
    configDialog.saving = false;
  }
};

const runBackup = async () => {
  try {
    await ElMessageBox.confirm('Hệ thống sẽ chạy background để tạo bản nén database và file upload. Tiếp tục?', 'Xác nhận chạy Backup', {
      type: 'warning'
    });
    running.value = true;
    const res = await backupApi.runBackup();
    ElMessage.success(res.data?.message || 'Đã gửi lệnh backup. Vui lòng F5 sau vài phút để xem kết quả.');
    
    // Auto reload list to see "pending"
    setTimeout(fetchData, 2000);
  } catch (err: any) {
    if (err !== 'cancel') {
      ElMessage.error('Lỗi khởi chạy: ' + (err.response?.data?.message || err.message));
    }
  } finally {
    running.value = false;
  }
};

const formatSize = (bytes: number) => {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

const formatDate = (dateStr: string) => {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleString('vi-VN');
};

const formatStatus = (status: string) => {
  switch (status) {
    case 'success': return 'Thành công';
    case 'failed': return 'Thất bại';
    case 'pending': return 'Đang xử lý';
    case 'deleted': return 'Đã xóa cũ';
    default: return status;
  }
};

const getStatusType = (status: string) => {
  switch (status) {
    case 'success': return 'success';
    case 'failed': return 'danger';
    case 'pending': return 'warning';
    case 'deleted': return 'info';
    default: return 'info';
  }
};

onMounted(() => {
  fetchData();
});
</script>


