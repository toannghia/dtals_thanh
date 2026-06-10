<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { useAuthStore } from '../../../store/auth';
import { supportApi } from '../../../services/api';
import { ArrowLeft, PictureRounded, Check } from '@element-plus/icons-vue';

const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const currentUserId = authStore.user?.id;

const loading = ref(true);
const requestData = ref<any>(null);
const messages = ref<any[]>([]);

const newMessage = ref('');
const attachment = ref<File | null>(null);
const fileInput = ref<HTMLInputElement | null>(null);
const sending = ref(false);
const chatContainer = ref<HTMLElement | null>(null);
const apiBaseUrl = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '');
let refreshTimer: number | null = null;
const canSend = computed(() => newMessage.value.trim().length > 0 || !!attachment.value);

const fetchDetails = async () => {
    loading.value = true;
    try {
        const id = route.params.id as string;
        const res = await supportApi.getMessages(id);
        requestData.value = res.data.request || res.data.ticket || res.data;
        messages.value = res.data.messages || res.data.items || res.data.data || res.data || [];
        scrollToBottom();
    } catch (error: any) {
        ElMessage.error('Không thể tải chi tiết yêu cầu: ' + (error.response?.data?.message || error.message));
        router.push('/user/support');
    } finally {
        loading.value = false;
    }
};

const resolveAttachmentUrl = (url?: string) => {
    if (!url) return '';
    if (url.startsWith('http')) return url;
    const clean = url.startsWith('/') ? url : `/${url}`;
    return `${apiBaseUrl}${clean}`;
};

const scrollToBottom = async () => {
    await nextTick();
    if (chatContainer.value) {
        chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
    }
};

const triggerFileInput = () => {
    fileInput.value?.click();
};

const handleFileChange = (e: Event) => {
    const target = e.target as HTMLInputElement;
    if (target.files && target.files.length > 0) {
        const file = target.files[0];
        if (!file) return;
        const isImage = file.type === 'image/jpeg' || file.type === 'image/png';
        const isLt5M = file.size / 1024 / 1024 < 5;

        if (!isImage) {
            ElMessage.error('Chỉ hỗ trợ file ảnh JPG/PNG!');
            target.value = '';
            return;
        }
        if (!isLt5M) {
            ElMessage.error('Dung lượng ảnh không vượt quá 5MB!');
            target.value = '';
            return;
        }
        attachment.value = file;
    }
};

const removeAttachment = () => {
    attachment.value = null;
    if (fileInput.value) fileInput.value.value = '';
};

const sendMessage = async () => {
    if (!canSend.value) return;

    sending.value = true;
    try {
        const id = route.params.id as string;
        const formData = new FormData();
        formData.append('content', newMessage.value);
        if (attachment.value) {
            formData.append('attachment', attachment.value);
        }

        await supportApi.addMessage(id, formData);
        
        // Refresh messages
        newMessage.value = '';
        removeAttachment();
        await fetchDetails();
    } catch (error: any) {
        ElMessage.error('Lỗi gửi tin nhắn: ' + (error.response?.data?.message || error.message));
    } finally {
        sending.value = false;
    }
};

const getStatusType = (status: string) => {
    return status === 'RESOLVED' ? 'success' : (status === 'IN_PROGRESS' ? 'primary' : (status === 'CLOSED' ? 'info' : 'warning'));
};
const getStatusLabel = (status: string) => {
    switch (status) {
        case 'PENDING': return 'Đang chờ xử lý';
        case 'IN_PROGRESS': return 'Đang hỗ trợ';
        case 'RESOLVED': return 'Đã xong';
        case 'CLOSED': return 'Đã đóng';
        default: return status;
    }
};

onMounted(() => {
    fetchDetails();
    refreshTimer = window.setInterval(fetchDetails, 3000);
});

onBeforeUnmount(() => {
    if (refreshTimer) {
        clearInterval(refreshTimer);
        refreshTimer = null;
    }
});
</script>

<template>
    <div class="support-detail-page flex flex-col h-[80vh] bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <!-- Header -->
        <div class="p-4 border-b border-gray-100 bg-gray-50 flex justify-between items-center shadow-sm z-10 shrink-0">
            <div class="flex items-center gap-3">
                <el-button link @click="router.push('/user/support')" class="text-gray-500 hover:text-blue-600">
                    <el-icon :size="20"><ArrowLeft /></el-icon>
                </el-button>
                <div v-if="requestData">
                    <div class="flex items-center gap-2">
                        <span class="font-mono text-xs bg-gray-200 text-gray-700 px-2 py-0.5 rounded">{{ requestData.code }}</span>
                        <el-tag :type="getStatusType(requestData.status)" size="small" effect="dark">{{ getStatusLabel(requestData.status) }}</el-tag>
                    </div>
                    <h2 class="text-lg font-bold text-gray-800 mt-1">{{ requestData.subject }}</h2>
                </div>
            </div>
            <div>
                <!-- Extra actions if needed -->
            </div>
        </div>

        <!-- Chat Area -->
        <div class="flex-1 overflow-y-auto p-6 bg-[#f8fbff]" ref="chatContainer" v-loading="loading">
            <div class="max-w-3xl mx-auto space-y-6">
                <!-- Messages -->
                <div v-for="msg in messages" :key="msg.id" class="flex w-full" :class="msg.senderId == currentUserId ? 'justify-end' : 'justify-start'">
                    
                    <!-- Admin / Tech Avatar -->
                    <div v-if="msg.senderId != currentUserId" class="w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center font-bold text-xs mr-3 mt-1 shadow-sm shrink-0">
                        {{ msg.sender?.role === 'TECH' ? 'T' : 'A' }}
                    </div>

                    <div class="max-w-[75%]">
                        <!-- Sender Name -->
                        <div class="text-[11px] text-gray-400 mb-1 flex items-center gap-2" :class="msg.senderId == currentUserId ? 'justify-end' : 'justify-start'">
                            <span>{{ msg.senderId == currentUserId ? 'Bạn' : (msg.sender?.fullName || 'Hỗ trợ viên') }}</span>
                            <span class="text-gray-300">•</span>
                            <span>{{ new Date(msg.createdAt).toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' }) }}</span>
                        </div>
                        
                        <!-- Bubble -->
                        <div class="p-3 rounded-2xl shadow-sm relative group"
                             :class="msg.senderId == currentUserId ? 'bg-blue-600 text-white rounded-tr-none' : 'bg-white text-gray-800 border border-gray-100 rounded-tl-none'">
                            
                            <p class="whitespace-pre-wrap text-[15px] leading-relaxed break-words">{{ msg.content || msg.message || msg.text }}</p>
                            
                            <!-- Image Attachment -->
                            <div v-if="msg.attachmentUrl || msg.attachment || msg.fileUrl" class="mt-3 relative rounded-lg overflow-hidden border" :class="msg.senderId == currentUserId ? 'border-blue-400/50' : 'border-gray-200'">
                                <el-image 
                                    :src="resolveAttachmentUrl(msg.attachmentUrl || msg.attachment || msg.fileUrl)" 
                                    fit="cover" 
                                    class="w-full max-h-64 object-cover hover:scale-105 transition-transform duration-300 cursor-pointer"
                                    :preview-src-list="[resolveAttachmentUrl(msg.attachmentUrl || msg.attachment || msg.fileUrl)]"
                                />
                            </div>
                        </div>
                    </div>

                    <!-- User Avatar -->
                    <div v-if="msg.senderId == currentUserId" class="w-8 h-8 rounded-full bg-gray-200 text-gray-600 flex items-center justify-center font-bold text-xs ml-3 mt-1 shadow-sm shrink-0">
                        Me
                    </div>
                </div>
                
                <!-- Resolved Notice -->
                <div v-if="requestData?.status === 'RESOLVED' || requestData?.status === 'CLOSED'" class="text-center my-6 pb-4">
                    <div class="inline-flex items-center justify-center bg-gray-100 p-3 rounded-full mb-3">
                        <el-icon class="text-gray-400 text-xl"><Check /></el-icon>
                    </div>
                    <p class="text-sm text-gray-500 font-medium">Yêu cầu này đã được đánh dấu {{ getStatusLabel(requestData.status).toLowerCase() }}.</p>
                    <p v-if="requestData?.status === 'RESOLVED'" class="text-xs text-gray-400 mt-1">Bạn có thể gửi tin nhắn mới để mở lại yêu cầu nếu cần.</p>
                </div>
            </div>
        </div>

        <!-- Input Area -->
        <div class="p-4 bg-white border-t border-gray-100 shrink-0" v-if="requestData?.status !== 'CLOSED'">
            <div class="max-w-3xl mx-auto">
                <div v-if="attachment" class="mb-3 flex items-center gap-2 bg-blue-50 text-blue-700 py-1.5 px-3 rounded-md w-fit border border-blue-100">
                    <el-icon><PictureRounded /></el-icon>
                    <span class="text-xs max-w-[200px] truncate font-medium">{{ attachment.name }}</span>
                    <el-button link type="danger" size="small" class="ml-2" @click="removeAttachment">Xóa</el-button>
                </div>
                
                <div class="flex items-end gap-3 bg-gray-50 p-2 rounded-xl border border-gray-200 focus-within:border-blue-400 focus-within:ring-1 focus-within:ring-blue-400 transition-all">
                    <!-- Hidden input file -->
                    <input type="file" ref="fileInput" class="hidden" accept="image/jpeg,image/png" @change="handleFileChange" />
                    
                    <el-button class="shrink-0 rounded-full h-10 w-10 !p-0 !bg-white border-0 shadow-sm text-gray-500 hover:text-blue-600" @click="triggerFileInput" :disabled="sending">
                        <el-icon :size="20"><PictureRounded /></el-icon>
                    </el-button>

                    <el-input
                        v-model="newMessage"
                        type="textarea"
                        :autosize="{ minRows: 1, maxRows: 4 }"
                        placeholder="Nhập nội dung tin nhắn..."
                        class="custom-chat-input"
                        resize="none"
                        @keydown.enter.exact.prevent="sendMessage"
                    />

                    <el-button type="primary" class="shrink-0 rounded-full h-10 px-5 shadow-sm shadow-blue-500/30" @click="sendMessage" :loading="sending" :disabled="sending || !canSend">
                        Gửi
                    </el-button>
                </div>
                <div class="text-[10px] text-gray-400 mt-2 text-center">
                    Nhấn Enter để gửi, Shift + Enter để xuống dòng. Hỗ trợ 1 ảnh (JPG/PNG, max 5MB).
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.support-detail-page {
    animation: slideUp 0.3s ease-out;
}
@keyframes slideUp {
    from { opacity: 0; transform: translateY(15px); }
    to { opacity: 1; transform: translateY(0); }
}

:deep(.custom-chat-input .el-textarea__inner) {
    background: transparent;
    border: none;
    box-shadow: none;
    padding: 8px 0;
    font-size: 15px;
    line-height: 1.5;
}
:deep(.custom-chat-input .el-textarea__inner:focus) {
    box-shadow: none;
}
</style>
