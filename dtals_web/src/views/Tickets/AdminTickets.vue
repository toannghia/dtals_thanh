<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { ticketApi } from '../../services/api';
import { ElMessage } from 'element-plus';
import { } from '@element-plus/icons-vue';

const loading = ref(false);
const tickets = ref<any[]>([]);
const showDetail = ref(false);
const currentTicket = ref<any>(null);
const adminNote = ref('');
const submittting = ref(false);

const fetchTickets = async () => {
  loading.value = true;
  try {
    const res = await ticketApi.list();
    tickets.value = res.data || [];
  } catch (error: any) {
    ElMessage.error('Lỗi tải danh sách yêu cầu');
  } finally {
    loading.value = false;
  }
};

const openDetail = (ticket: any) => {
  currentTicket.value = ticket;
  adminNote.value = ticket.adminNote || '';
  showDetail.value = true;
};

const updateStatus = async (status: string) => {
  if (status === 'REJECTED' && !adminNote.value.trim()) {
    return ElMessage.warning('Vui lòng nhập ghi chú lý do từ chối');
  }

  submittting.value = true;
  try {
    await ticketApi.updateStatus(currentTicket.value.id, {
      status,
      adminNote: adminNote.value
    });
    ElMessage.success('Cập nhật trạng thái thành công');
    showDetail.value = false;
    fetchTickets();
  } catch (error: any) {
    ElMessage.error('Lỗi cập nhật trạng thái');
  } finally {
    submittting.value = false;
  }
};

const getStatusType = (status: string) => {
  switch (status) {
    case 'APPROVED': return 'success';
    case 'REJECTED': return 'danger';
    case 'PENDING': return 'warning';
    default: return 'info';
  }
};

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'APPROVED': return 'Đã duyệt';
    case 'REJECTED': return 'Từ chối';
    case 'PENDING': return 'Chờ duyệt';
    case 'COMPLETED': return 'Hoàn thành';
    default: return status;
  }
};

onMounted(fetchTickets);
</script>

<template>
  <div class="admin-tickets">
    <div class="mb-6 flex justify-between items-center">
      <h2 class="text-2xl font-bold text-gray-700">Quản lý yêu cầu từ CQNN</h2>
      <el-button @click="fetchTickets" icon="Refresh">Làm mới</el-button>
    </div>

    <el-card shadow="hover" class="!border-none !rounded-xl">
      <el-table :data="tickets" stripe v-loading="loading">
        <el-table-column prop="code" label="Mã phiếu" width="140">
          <template #default="{ row }">
            <span class="font-mono font-bold text-blue-600">{{ row.code }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="subject" label="Tiêu đề" min-width="200" />
        <el-table-column label="Người gửi" width="180">
          <template #default="{ row }">
            <div>{{ row.createdBy?.username }}</div>
            <div class="text-xs text-gray-400 italic">
               {{ row.createdBy?.role?.name || 'Cơ quan HN' }}
            </div>
          </template>
        </el-table-column>
        <el-table-column label="Ngày gửi" width="160">
          <template #default="{ row }">
            {{ new Date(row.createdAt).toLocaleString('vi-VN') }}
          </template>
        </el-table-column>
        <el-table-column label="Trạng thái" width="130" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">{{ getStatusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Thao tác" width="120" align="center" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" plain @click="openDetail(row)">
              Chi tiết
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="showDetail" title="Chi tiết yêu cầu" width="600px">
      <div v-if="currentTicket" class="space-y-4">
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span class="text-gray-400 block uppercase text-[10px] font-bold">Mã phiếu</span>
            <span class="font-mono font-bold">{{ currentTicket.code }}</span>
          </div>
          <div>
            <span class="text-gray-400 block uppercase text-[10px] font-bold">Trạng thái</span>
            <el-tag :type="getStatusType(currentTicket.status)" size="small">
              {{ getStatusLabel(currentTicket.status) }}
            </el-tag>
          </div>
          <div class="col-span-2">
            <span class="text-gray-400 block uppercase text-[10px] font-bold">Tiêu đề</span>
            <span class="font-medium text-gray-700">{{ currentTicket.subject }}</span>
          </div>
          <div class="col-span-2">
            <span class="text-gray-400 block uppercase text-[10px] font-bold">Lý do từ CQNN</span>
            <div class="bg-gray-50 p-3 rounded border border-gray-100 italic text-gray-600">
               "{{ currentTicket.reason }}"
            </div>
          </div>
        </div>

        <el-divider content-position="left">Phản hồi của Admin</el-divider>
        
        <el-form label-position="top">
          <el-form-item label="Ghi chú nội bộ / Phản hồi">
            <el-input 
              v-model="adminNote" 
              type="textarea" 
              :rows="3" 
              placeholder="Nhập phản hồi cho cơ quan nhà nước..."
              :disabled="currentTicket.status !== 'PENDING'"
            />
          </el-form-item>
        </el-form>

        <div v-if="currentTicket.status === 'PENDING'" class="flex justify-end gap-3 mt-6">
          <el-button type="danger" plain @click="updateStatus('REJECTED')" :loading="submittting">Từ chối</el-button>
          <el-button type="success" @click="updateStatus('APPROVED')" :loading="submittting">Duyệt yêu cầu</el-button>
        </div>
        <div v-else class="text-center text-gray-400 text-sm italic py-4">
          Phiếu này đã được xử lý bởi {{ currentTicket.resolvedBy?.username || 'Hệ thống' }}.
        </div>
      </div>
    </el-dialog>
  </div>
</template>
