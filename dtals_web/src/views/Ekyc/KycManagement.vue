<template>
  <div>

    <el-card shadow="hover" class="!border-none !rounded-xl min-h-[500px]">
      
      <!-- Filters -->
      <div class="flex justify-between items-center mb-6">
        <el-radio-group v-model="statusFilter" @change="loadSubmissions">
          <el-radio-button label="">Tất cả</el-radio-button>
          <el-radio-button label="NEEDS_REVIEW">Chờ duyệt</el-radio-button>
          <el-radio-button label="APPROVED">Đã duyệt</el-radio-button>
          <el-radio-button label="REJECTED">Từ chối</el-radio-button>
        </el-radio-group>
        
        <el-input v-model="searchQuery" placeholder="Tìm tên/email" style="width: 250px" clearable @clear="loadSubmissions" @keyup.enter="loadSubmissions">
          <template #append>
            <el-button icon="Search" @click="loadSubmissions" />
          </template>
        </el-input>
      </div>

      <!-- Table -->
      <el-table v-loading="loading" :data="submissions" border stripe>
        <el-table-column type="index" label="STT" width="60" align="center" />
        
        <el-table-column label="Thông tin End User" min-width="200">
          <template #default="{ row }">
            <div class="font-bold text-blue-700">{{ row.user?.fullName || row.user?.username }}</div>
            <div class="text-xs text-gray-500">{{ row.user?.email }}</div>
          </template>
        </el-table-column>
        
        <el-table-column label="AI Score (Khuôn mặt)" width="180" align="center">
          <template #default="{ row }">
             <div v-if="row.faceMatchScore !== undefined && row.faceMatchScore !== null">
               <el-progress 
                :percentage="Number(row.faceMatchScore)" 
                :color="getScoreColor(row.faceMatchScore)" 
                :stroke-width="8"
               />
               <span class="text-xs text-gray-500">{{ row.faceMatchScore }}% matches</span>
             </div>
             <span v-else class="text-gray-400">Không có dữ liệu</span>
          </template>
        </el-table-column>
        
        <el-table-column label="Ngày gửi" width="160" align="center">
          <template #default="{ row }">
            {{ formatDate(row.createdAt) }}
          </template>
        </el-table-column>

        <el-table-column label="Trạng thái" width="140" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusTag(row.status)">
               {{ getStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="Thao tác" width="200" align="center">
          <template #default="{ row }">
            <el-button size="small" type="primary" plain @click="openReview(row)">Xem hồ sơ</el-button>
            <el-button size="small" type="danger" plain @click="deleteSubmission(row)">Xóa</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="mt-6 flex justify-end">
        <el-pagination 
          background 
          layout="prev, pager, next" 
          :total="total" 
          v-model:current-page="currentPage"
          @current-change="loadSubmissions"
        />
      </div>
    </el-card>

    <!-- Review Dialog -->
    <el-dialog v-model="showReviewDialog" title="Chi tiết Hồ sơ eKYC" width="800px" top="5vh">
      <div v-loading="reviewLoading" v-if="currentSubmission" class="space-y-6">
        
        <!-- User Info & Status -->
        <div class="flex justify-between items-center bg-gray-50 p-4 rounded-lg border border-gray-100">
          <div>
            <h3 class="font-bold text-lg text-gray-800">{{ currentSubmission.user?.fullName || currentSubmission.user?.username }}</h3>
            <p class="text-sm text-gray-500">{{ currentSubmission.user?.email }}</p>
          </div>
          <div class="text-right">
             <el-tag :type="getStatusTag(currentSubmission.status)" size="large" class="mb-1">
               {{ getStatusLabel(currentSubmission.status) }}
             </el-tag>
             <div v-if="currentSubmission.faceMatchScore" class="text-xs font-bold font-mono text-blue-600 mt-1">
               Face Match: {{ currentSubmission.faceMatchScore }}%
             </div>
          </div>
        </div>

        <!-- Images Grid -->
        <div>
          <h4 class="font-bold mb-3 border-b pb-2">Hình ảnh cung cấp</h4>
          <div class="grid grid-cols-3 gap-4">
            <div class="text-center">
              <span class="text-xs text-gray-500 mb-1 block">Mặt trước CCCD</span>
              <el-image 
                :src="getImageUrl(currentSubmission.frontImagePath)" 
                :preview-src-list="[getImageUrl(currentSubmission.frontImagePath)]"
                class="w-full h-32 rounded border object-cover shadow-sm cursor-pointer hover:opacity-90"
                fit="cover" />
            </div>
            <div class="text-center">
              <span class="text-xs text-gray-500 mb-1 block">Mặt sau CCCD</span>
              <el-image 
                :src="getImageUrl(currentSubmission.backImagePath)" 
                :preview-src-list="[getImageUrl(currentSubmission.backImagePath)]"
                class="w-full h-32 rounded border object-cover shadow-sm cursor-pointer hover:opacity-90"
                fit="cover" />
            </div>
            <div class="text-center">
              <span class="text-xs text-gray-500 mb-1 block">Ảnh Selfie (Chân dung)</span>
              <el-image 
                :src="getImageUrl(currentSubmission.selfieImagePath)" 
                :preview-src-list="[getImageUrl(currentSubmission.selfieImagePath)]"
                class="w-full h-32 rounded border object-cover shadow-sm cursor-pointer hover:opacity-90"
                fit="cover" />
            </div>
          </div>
        </div>

        <!-- OCR Data -->
        <div v-if="currentSubmission.ocrData">
          <h4 class="font-bold mb-3 border-b pb-2">Dữ liệu trích xuất (OCR)</h4>
          <div class="bg-gray-50 p-4 rounded-lg text-sm border border-gray-100 grid grid-cols-2 gap-y-3">
             <template v-if="parsedOcr">
                <div><span class="text-gray-500 underline mr-1">Số CCCD:</span> <strong class="text-black">{{ parsedOcr.id || 'N/A' }}</strong></div>
                <div><span class="text-gray-500 underline mr-1">Họ tên:</span> <strong class="text-black">{{ parsedOcr.name || 'N/A' }}</strong></div>
                <div><span class="text-gray-500 underline mr-1">Ngày sinh:</span> <strong class="text-black">{{ parsedOcr.birth_day || parsedOcr.birthday || 'N/A' }}</strong></div>
                <div><span class="text-gray-500 underline mr-1">Giới tính:</span> <strong class="text-black">{{ parsedOcr.gender || 'N/A' }}</strong></div>
                <div class="col-span-2"><span class="text-gray-500 underline mr-1">Quê quán:</span> <strong class="text-black">{{ parsedOcr.origin_location || parsedOcr.home || 'N/A' }}</strong></div>
                <div class="col-span-2"><span class="text-gray-500 underline mr-1">Thường trú:</span> <strong class="text-black">{{ parsedOcr.recent_location || parsedOcr.address || 'N/A' }}</strong></div>
             </template>
             <div v-else class="col-span-2 text-gray-400 italic">Không thể parse dữ liệu OCR</div>
          </div>
        </div>

        <!-- Review Action Area -->
        <div v-if="currentSubmission.status === 'NEEDS_REVIEW' || currentSubmission.status === 'PENDING'" class="pt-4 border-t border-gray-200 mt-6">
          <h4 class="font-bold mb-3">Quyết định phê duyệt</h4>
          <el-input 
            v-model="reviewNote" 
            type="textarea" 
            :rows="3" 
            placeholder="Ghi chú thêm (Bắt buộc nếu Từ chối)" 
            class="mb-4"
          />
          <div class="flex justify-end gap-3">
            <el-button type="danger" plain @click="submitReview('REJECTED')">Từ chối hồ sơ</el-button>
            <el-button type="success" @click="submitReview('APPROVED')">Duyệt hợp lệ</el-button>
          </div>
        </div>

         <!-- Review Result Area -->
         <div v-else class="pt-4 border-t border-gray-200 mt-6 bg-gray-50 p-4 rounded">
            <h4 class="font-bold text-gray-600 text-sm mb-1">Kết quả đánh giá</h4>
            <p class="text-sm">Hồ sơ đã được <strong :class="currentSubmission.status === 'APPROVED' ? 'text-green-600' : 'text-red-600'">{{ getStatusLabel(currentSubmission.status) }}</strong>.</p>
            <p v-if="currentSubmission.reviewNotes" class="text-sm mt-2 text-gray-500 italic">"{{ currentSubmission.reviewNotes }}"</p>
         </div>
         
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { adminEkycApi } from '../../services/api';

const submissions = ref<any[]>([]);
const total = ref(0);
const currentPage = ref(1);
const loading = ref(true);
const statusFilter = ref('');
const searchQuery = ref('');

const showReviewDialog = ref(false);
const currentSubmission = ref<any>(null);
const reviewLoading = ref(false);
const reviewNote = ref('');

onMounted(() => {
  loadSubmissions();
});

const loadSubmissions = async () => {
  loading.value = true;
  try {
    const params: any = { page: currentPage.value, limit: 20 };
    if (statusFilter.value) params.status = statusFilter.value;
    // Note: Add search query if backend supports it natively
    
    const res = await adminEkycApi.list(params);
    submissions.value = res.data?.data || res.data?.items || res.data || [];
    total.value = res.data?.meta?.total || res.data?.total || submissions.value.length;
  } catch (error) {
    console.error('Lỗi khi tải danh sách eKYC', error);
  } finally {
    loading.value = false;
  }
};

const openReview = async (row: any) => {
  currentSubmission.value = row;
  reviewNote.value = '';
  showReviewDialog.value = true;
  reviewLoading.value = true;
  
  try {
    // Optionally fetch full details if the list doesn't include images/ocr
    const res = await adminEkycApi.getDetail(row.id);
    currentSubmission.value = res.data;
  } catch (err) {
    console.error('Không tải được chi tiết KYC', err);
    // Continue with row data if fetch fails
  } finally {
    reviewLoading.value = false;
  }
};

const submitReview = async (status: 'APPROVED' | 'REJECTED') => {
  if (status === 'REJECTED' && !reviewNote.value.trim()) {
    ElMessage.warning('Vui lòng nhập lý do (Ghi chú) khi từ chối hồ sơ.');
    return;
  }

  const actionText = status === 'APPROVED' ? 'Duyệt hợp lệ' : 'Từ chối';
  ElMessageBox.confirm(`Bạn có chắc muốn ${actionText} hồ sơ này?`, 'Xác nhận', {
    confirmButtonText: 'Đồng ý',
    cancelButtonText: 'Hủy'
  }).then(async () => {
    try {
      await adminEkycApi.review(currentSubmission.value.id, {
        status,
        reviewNote: reviewNote.value,
      });
      ElMessage.success(`Đã ${actionText.toLowerCase()} hồ sơ thành công`);
      showReviewDialog.value = false;
      await loadSubmissions();
    } catch (e: any) {
      ElMessage.error(e.response?.data?.message || 'Có lỗi xảy ra khi duyệt');
    }
  }).catch(() => {});
};

const deleteSubmission = async (row: any) => {
  ElMessageBox.confirm('Bạn có chắc muốn xóa hồ sơ eKYC này?', 'Xác nhận xóa', {
    confirmButtonText: 'Xóa',
    cancelButtonText: 'Hủy',
    type: 'warning',
  }).then(async () => {
    try {
      await adminEkycApi.delete(row.id);
      ElMessage.success('Đã xóa hồ sơ thành công');
      await loadSubmissions();
    } catch (e: any) {
      ElMessage.error(e.response?.data?.message || 'Có lỗi xảy ra khi xóa');
    }
  }).catch(() => {});
};

const parsedOcr = computed(() => {
  if (!currentSubmission.value?.ocrData) return null;
  try {
    return typeof currentSubmission.value.ocrData === 'string' 
      ? JSON.parse(currentSubmission.value.ocrData) 
      : currentSubmission.value.ocrData;
  } catch {
    return null;
  }
});

const getImageUrl = (path: string) => {
  if (!path) return '';
  if (path.startsWith('http')) return path;
  // Fallback to static serving base if purely relative path stored in DB
  return `http://localhost:3000/${path}`;
};

const getScoreColor = (score: number) => {
  if (score >= 80) return '#67c23a'; // success
  if (score >= 60) return '#e6a23c'; // warning
  return '#f56c6c'; // danger
};

const getStatusTag = (status: string) => {
  switch (status) {
    case 'APPROVED': return 'success';
    case 'NEEDS_REVIEW': return 'warning';
    case 'PENDING': return 'info';
    case 'REJECTED': return 'danger';
    default: return 'info';
  }
};

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'APPROVED': return 'Đã phê duyệt';
    case 'NEEDS_REVIEW': return 'Chờ duyệt';
    case 'PENDING': return 'Đang xử lý AI';
    case 'REJECTED': return 'Bị từ chối';
    default: return 'Không xác định';
  }
};

const formatDate = (dateInput: string | Date) => {
  if (!dateInput) return '-';
  const date = new Date(dateInput);
  return `${date.toLocaleDateString('vi-VN')} ${date.toLocaleTimeString('vi-VN', {hour: '2-digit', minute:'2-digit'})}`;
};
</script>
