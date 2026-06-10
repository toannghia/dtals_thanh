<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { governmentApi } from '../../services/api';
import { ElMessage } from 'element-plus';
import { Calendar, Clock } from '@element-plus/icons-vue';

const loading = ref(false);
const tickets = ref<any[]>([]);

const fetchTickets = async () => {
  loading.value = true;
  try {
    const res = await governmentApi.getTickets();
    tickets.value = res.data || [];
  } catch (e: any) {
    ElMessage.error('Lỗi tải lịch sử yêu cầu: ' + (e.response?.data?.message || e.message));
  } finally {
    loading.value = false;
  }
};

const getStatusType = (status: string) => {
  switch (status) {
    case 'APPROVED': return 'success';
    case 'REJECTED': return 'danger';
    case 'COMPLETED': return 'info';
    case 'PENDING': return 'warning';
    default: return 'info';
  }
};

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'APPROVED': return 'Đã duyệt';
    case 'REJECTED': return 'Từ chối';
    case 'COMPLETED': return 'Hoàn thành';
    case 'PENDING': return 'Chờ duyệt';
    default: return status;
  }
};

onMounted(fetchTickets);
</script>

<template>
  <div class="gov-tickets">
    <div class="mb-6 flex justify-between items-center">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Lịch sử yêu cầu</h2>
        <p class="text-gray-500">Danh sách các yêu cầu điều khiển/tắt trạm đã gửi.</p>
      </div>
      <el-button @click="fetchTickets" icon="Refresh" type="primary" plain>Làm mới</el-button>
    </div>

    <div v-loading="loading">
      <el-empty v-if="tickets.length === 0 && !loading" description="Chưa có yêu cầu nào được gửi" />
      
      <el-row v-else :gutter="20">
        <el-col v-for="ticket in tickets" :key="ticket.id" :span="24" class="mb-4">
          <el-card shadow="hover" class="ticket-card">
            <template #header>
              <div class="flex justify-between items-center">
                <div class="flex items-center gap-2">
                  <el-tag effect="dark" type="info" class="font-mono">{{ ticket.code }}</el-tag>
                  <span class="font-bold text-gray-700">{{ ticket.subject }}</span>
                </div>
                <el-tag :type="getStatusType(ticket.status)">
                  {{ getStatusLabel(ticket.status) }}
                </el-tag>
              </div>
            </template>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 p-2">
              <div>
                <div class="flex items-start gap-2 mb-3">
                  <el-icon class="mt-1 text-gray-400"><Calendar /></el-icon>
                  <div>
                    <div class="text-xs text-gray-400 uppercase font-bold">Ngày tạo</div>
                    <div class="text-sm">{{ new Date(ticket.createdAt).toLocaleString() }}</div>
                  </div>
                </div>
                <div class="flex items-start gap-2">
                  <el-icon class="mt-1 text-gray-400"><Clock /></el-icon>
                  <div>
                    <div class="text-xs text-gray-400 uppercase font-bold">Lý do</div>
                    <div class="text-sm italic text-gray-600">"{{ ticket.reason }}"</div>
                  </div>
                </div>
              </div>
              
              <div class="bg-gray-50 p-3 rounded-lg border border-dashed border-gray-200" v-if="ticket.adminNote || ticket.status !== 'PENDING'">
                <div class="text-xs text-gray-400 uppercase font-bold mb-2">Phản hồi từ Quản trị viên</div>
                <div v-if="ticket.adminNote" class="text-sm text-gray-700">{{ ticket.adminNote }}</div>
                <div v-else class="text-sm text-gray-400 italic">Đang chờ xử lý...</div>
                
                <div v-if="ticket.resolvedAt" class="mt-3 pt-3 border-t border-gray-200 text-xs text-gray-400">
                  Xử lý lúc: {{ new Date(ticket.resolvedAt).toLocaleString() }}
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<style scoped>
.ticket-card {
  border-radius: 12px;
  overflow: hidden;
}
:deep(.el-card__header) {
  padding: 12px 20px;
  background-color: #f8fafc;
}
</style>
