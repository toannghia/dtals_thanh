<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { supportApi } from '../../../services/api';
import { Plus, ChatDotRound } from '@element-plus/icons-vue';

const router = useRouter();

const loading = ref(true);
const requests = ref<any[]>([]);
const total = ref(0);
const filters = reactive({ page: 1, limit: 10 });

const fetchRequests = async () => {
  loading.value = true;
  try {
    const res = await supportApi.list(filters);
    requests.value = res.data.items || [];
    total.value = res.data.total || 0;
  } catch (error: any) {
    ElMessage.error('Lỗi tải danh sách yêu cầu hỗ trợ: ' + (error.response?.data?.message || error.message));
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
    case 'PENDING': return 'Đang chờ xử lý';
    case 'IN_PROGRESS': return 'Đang hỗ trợ';
    case 'RESOLVED': return 'Đã xử lý xong';
    case 'CLOSED': return 'Đã đóng';
    default: return status;
  }
};

// --- Create New Request Modal ---
const dialogVisible = ref(false);
const submitting = ref(false);
const newRequest = reactive({
  subject: '',
  message: '',
});
const attachmentList = ref<any[]>([]);

const handleExceed = () => {
  ElMessage.warning('Chỉ được phép tải lên 1 ảnh duy nhất. Xóa ảnh cũ trước khi tải ảnh mới.');
};

const handleBeforeUpload = (file: File) => {
  const isImage = file.type === 'image/jpeg' || file.type === 'image/png';
  const isLt5M = file.size / 1024 / 1024 < 5;

  if (!isImage) {
    ElMessage.error('Chỉ hỗ trợ file ảnh JPG/PNG!');
    return false;
  }
  if (!isLt5M) {
    ElMessage.error('Dung lượng ảnh không được vượt quá 5MB!');
    return false;
  }
  return true;
};

const submitNewRequest = async () => {
  if (!newRequest.subject.trim() || !newRequest.message.trim()) {
    ElMessage.warning('Vui lòng nhập đầy đủ Tiêu đề và Nội dung!');
    return;
  }

  submitting.value = true;
  try {
    const formData = new FormData();
    formData.append('subject', newRequest.subject);
    formData.append('message', newRequest.message);
    
    if (attachmentList.value.length > 0) {
      formData.append('attachment', attachmentList.value[0].raw);
    }

    await supportApi.create(formData);
    ElMessage.success('Gửi yêu cầu hỗ trợ thành công!');
    dialogVisible.value = false;
    newRequest.subject = '';
    newRequest.message = '';
    attachmentList.value = [];
    filters.page = 1;
    fetchRequests();
  } catch (error: any) {
    ElMessage.error('Lỗi khi gửi yêu cầu: ' + (error.response?.data?.message || error.message));
  } finally {
    submitting.value = false;
  }
};

onMounted(() => {
  fetchRequests();
});
</script>

<template>
  <div class="support-list-page">
    <div class="flex justify-between items-center mb-6">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Hỗ trợ kỹ thuật</h2>
        <p class="text-gray-500">Gửi và theo dõi các yêu cầu hỗ trợ từ đội ngũ kỹ thuật DTALS.</p>
      </div>
      <el-button type="primary" size="large" @click="dialogVisible = true" class="shadow-md shadow-blue-500/30">
        <el-icon class="mr-2"><Plus /></el-icon> Tạo yêu cầu mới
      </el-button>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div v-if="requests.length === 0 && !loading" class="p-16 text-center">
        <el-icon class="text-6xl text-gray-200 mb-4"><ChatDotRound /></el-icon>
        <p class="text-gray-500 text-lg">Bạn chưa có yêu cầu hỗ trợ nào.</p>
        <el-button type="primary" plain class="mt-4" @click="dialogVisible = true">Gửi yêu cầu đầu tiên</el-button>
      </div>

      <div v-else class="p-0">
        <el-table :data="requests" v-loading="loading" style="width: 100%" row-class-name="cursor-pointer" @row-click="(row: any) => router.push(`/user/support/${row.id}`)">
          <el-table-column prop="code" label="Mã Y/C" width="120">
            <template #default="{ row }">
              <span class="font-mono text-gray-600 font-medium">{{ row.code }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="subject" label="Tiêu đề sự cố" min-width="300">
            <template #default="{ row }">
              <span class="font-medium text-gray-800">{{ row.subject || row.title }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="updatedAt" label="Cập nhật lần cuối" width="180">
            <template #default="{ row }">
              <span class="text-gray-500">{{ new Date(row.updatedAt).toLocaleString('vi-VN') }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="Trạng thái" width="160" align="center">
            <template #default="{ row }">
              <el-tag :type="getStatusTagType(row.status)" effect="light">
                {{ getStatusLabel(row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="" width="80" align="right">
            <template #default>
              <el-button link type="primary">Chi tiết</el-button>
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

    <!-- Create Request Dialog -->
    <el-dialog v-model="dialogVisible" title="Gửi yêu cầu hỗ trợ mới" width="550px" destroy-on-close>
      <div class="flex flex-col gap-4 mt-2">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Tiêu đề / Vấn đề gặp phải <span class="text-red-500">*</span></label>
          <el-input v-model="newRequest.subject" placeholder="Vd: Không thể đăng nhập vào tài khoản NTRIP..." />
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Mô tả chi tiết <span class="text-red-500">*</span></label>
          <el-input v-model="newRequest.message" type="textarea" :rows="5" placeholder="Mô tả cụ thể sự cố (thời điểm, lỗi hiển thị...)" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Hình ảnh đính kèm (Tùy chọn)</label>
          <el-upload
            action="#"
            list-type="picture-card"
            :auto-upload="false"
            v-model:file-list="attachmentList"
            :limit="1"
            :on-exceed="handleExceed"
            :before-upload="handleBeforeUpload"
            accept="image/jpeg,image/png"
          >
            <el-icon><Plus /></el-icon>
            <template #tip>
              <div class="el-upload__tip text-xs text-gray-500 mt-1">
                Chỉ cho phép 1 ảnh JPG/PNG, tối đa 5MB.
              </div>
            </template>
          </el-upload>
        </div>
      </div>
      
      <template #footer>
        <div class="flex justify-end gap-2">
          <el-button @click="dialogVisible = false">Hủy</el-button>
          <el-button type="primary" :loading="submitting" @click="submitNewRequest">Gửi yêu cầu</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.support-list-page {
  animation: fadeIn 0.4s ease-out;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
