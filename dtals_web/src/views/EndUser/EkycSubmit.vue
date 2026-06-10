<template>
  <div>
    <!-- Alert for Status -->
    <div v-if="ekycStatus === 'NEEDS_REVIEW' || ekycStatus === 'PENDING'" class="mb-6">
      <el-alert title="Hồ sơ đang chờ phê duyệt" type="warning" description="Quản trị viên đang xem xét hồ sơ của bạn. Quá trình này có thể mất từ 1-2 ngày làm việc." show-icon :closable="false" />
      <div v-if="latestSubmission" class="mt-4">
        <el-card shadow="never" class="!border !rounded-lg">
          <div class="text-sm text-gray-600">Thời gian gửi: <strong>{{ formatDate(latestSubmission.createdAt) }}</strong></div>
        </el-card>
      </div>
    </div>

    <!-- VERIFIED / APPROVED: Full info card -->
    <div v-if="ekycStatus === 'APPROVED' || ekycStatus === 'VERIFIED'" class="mb-6">
      <el-alert title="Danh tính đã được xác minh" type="success" description="Hồ sơ eKYC của bạn đã được phê duyệt." show-icon :closable="false" />
      
      <!-- Detailed Verification Info -->
      <el-card shadow="hover" class="!border-none !rounded-xl mt-4" v-if="latestSubmission">
        <div class="space-y-4">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-bold text-gray-800">Thông tin xác thực</h3>
            <el-tag type="success" size="small">Đã xác minh</el-tag>
          </div>
          
          <!-- OCR Data -->
          <div v-if="latestSubmission.ocrData" class="bg-blue-50/50 p-4 rounded-lg text-sm border border-blue-100">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div><span class="text-gray-500">Số giấy tờ:</span> <strong>{{ parsedOcrData?.id || '-' }}</strong></div>
              <div><span class="text-gray-500">Họ và tên:</span> <strong>{{ parsedOcrData?.name || '-' }}</strong></div>
              <div><span class="text-gray-500">Ngày sinh:</span> <strong>{{ parsedOcrData?.birth_day || parsedOcrData?.birthday || '-' }}</strong></div>
              <div><span class="text-gray-500">Giới tính:</span> <strong>{{ parsedOcrData?.gender || '-' }}</strong></div>
              <div class="sm:col-span-2"><span class="text-gray-500">Quê quán:</span> <strong>{{ parsedOcrData?.origin_location || '-' }}</strong></div>
              <div class="sm:col-span-2"><span class="text-gray-500">Thường trú:</span> <strong>{{ parsedOcrData?.recent_location || '-' }}</strong></div>
            </div>
          </div>

          <!-- Scores -->
          <div class="grid grid-cols-2 gap-4 text-sm">
            <div v-if="latestSubmission.faceMatchScore != null">
              <span class="text-gray-500">Độ khớp khuôn mặt:</span>
              <strong :class="latestSubmission.faceMatchScore >= 80 ? 'text-green-600' : 'text-red-600'"> {{ latestSubmission.faceMatchScore }}%</strong>
            </div>
            <div v-if="latestSubmission.reviewedAt">
              <span class="text-gray-500">Ngày duyệt:</span>
              <strong>{{ formatDate(latestSubmission.reviewedAt) }}</strong>
            </div>
            <div v-if="latestSubmission.createdAt">
              <span class="text-gray-500">Ngày gửi:</span>
              <strong>{{ formatDate(latestSubmission.createdAt) }}</strong>
            </div>
          </div>
        </div>
      </el-card>

      <div class="mt-4">
        <el-button type="primary" @click="$router.push('/user/ntrip-accounts')">Tạo tài khoản NTRIP ngay</el-button>
        <el-button plain @click="$router.push('/user')">Về trang chủ</el-button>
      </div>
    </div>

    <div v-if="ekycStatus === 'REJECTED'" class="mb-6">
      <el-alert title="Hồ sơ bị từ chối" type="error" :description="`Hồ sơ của bạn bị từ chối với lý do: ${rejectReason || 'Không hợp lệ'}. Vui lòng nộp lại thông tin bên dưới.`" show-icon :closable="false" />
    </div>

    <!-- Submission Form -->
    <el-card v-if="['NONE', 'REJECTED'].includes(ekycStatus)" shadow="hover" class="!border-none !rounded-xl">
      <div class="space-y-6">
        
        <!-- Hướng dẫn trực quan (Visual Guidance) -->
        <div class="bg-gradient-to-br from-slate-50 via-white to-blue-50/10 border border-slate-200/60 rounded-3xl p-6 shadow-sm shadow-blue-500/5">
          <!-- SVG Gradient Definitions -->
          <svg class="hidden">
            <defs>
              <linearGradient id="blueCardGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#f0f9ff" />
                <stop offset="100%" stop-color="#e0f2fe" />
              </linearGradient>
              <linearGradient id="greenFaceGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#f0fdf4" />
                <stop offset="100%" stop-color="#dcfce7" />
              </linearGradient>
              <linearGradient id="redFaceGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#fff5f5" />
                <stop offset="100%" stop-color="#ffe3e3" />
              </linearGradient>
            </defs>
          </svg>

          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 cursor-pointer group pb-4 border-b border-slate-100" @click="showGuide = !showGuide">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-blue-600/10 flex items-center justify-center text-blue-600 shadow-sm shadow-blue-500/10 group-hover:scale-105 transition-transform duration-300">
                <el-icon class="text-lg"><Checked /></el-icon>
              </div>
              <div>
                <h3 class="font-bold text-slate-800 text-sm sm:text-base tracking-wide">Hướng dẫn chụp ảnh xác minh eKYC</h3>
                <p class="text-xs text-slate-500 mt-0.5">Vui lòng xem hướng dẫn để hồ sơ của bạn được phê duyệt tự động nhanh nhất</p>
              </div>
            </div>
            <el-button link type="primary" size="small" class="!text-xs font-semibold hover:opacity-85">
              {{ showGuide ? 'Thu gọn' : 'Xem hướng dẫn chi tiết' }}
              <el-icon class="ml-1">
                <ArrowUp v-if="showGuide" />
                <ArrowDown v-else />
              </el-icon>
            </el-button>
          </div>
          
          <div v-show="showGuide" class="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-5 mt-4">
            <!-- Video Hướng dẫn quét khuôn mặt -->
            <div class="lg:col-span-12 xl:col-span-4 space-y-3">
              <div class="flex items-center gap-2">
                <div class="w-1.5 h-6 rounded-full bg-blue-600"></div>
                <h4 class="font-bold text-slate-800 text-sm tracking-wide">Video hướng dẫn quét mặt</h4>
              </div>
              <div class="relative bg-slate-950 rounded-2xl overflow-hidden border border-slate-800/80 aspect-video flex items-center justify-center shadow-lg shadow-blue-900/10 group max-w-sm mx-auto w-full">
                <video 
                  :src="videoTutorialUrl" 
                  controls 
                  playsinline 
                  loop 
                  muted 
                  autoplay
                  class="w-full h-full object-contain opacity-90 group-hover:opacity-100 transition-opacity duration-300"
                ></video>
                <div class="absolute top-3 left-3 px-2.5 py-0.5 rounded-full bg-black/60 text-[9px] text-blue-400 font-bold uppercase tracking-wider border border-blue-500/20 backdrop-blur-sm">
                  Video Hướng dẫn
                </div>
              </div>
              <p class="text-[11px] text-slate-500 leading-relaxed text-center max-w-sm mx-auto">
                Nhìn thẳng, đưa khuôn mặt vào giữa vòng tròn và di chuyển nhẹ theo hướng dẫn trên màn hình.
              </p>
            </div>

            <!-- Hướng dẫn chụp giấy tờ -->
            <div class="lg:col-span-6 xl:col-span-4 space-y-4">
              <div class="flex items-center gap-2">
                <div class="w-1.5 h-6 rounded-full bg-blue-600"></div>
                <h4 class="font-bold text-slate-800 text-sm tracking-wide">1. Cách chụp Giấy tờ tùy thân</h4>
              </div>
              <div class="grid grid-cols-2 gap-3">
                <!-- Hợp lệ -->
                <div class="bg-white hover:bg-emerald-50/5 p-3 rounded-2xl border border-slate-100 hover:border-emerald-200/80 shadow-sm flex flex-col justify-between hover:-translate-y-1 hover:shadow-md hover:shadow-emerald-500/5 transition-all duration-300 relative overflow-hidden group">
                  <div class="absolute top-2 right-2 w-4 h-4 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-600">
                    <el-icon class="text-[10px]"><Check /></el-icon>
                  </div>
                  <div class="flex justify-center mb-2 mt-1">
                    <svg class="w-full h-14 max-w-[100px] group-hover:scale-105 transition-transform duration-300" viewBox="0 0 120 80">
                      <rect x="5" y="5" width="110" height="70" rx="6" fill="url(#blueCardGrad)" stroke="#0ea5e9" stroke-width="1" />
                      <rect x="12" y="15" width="24" height="30" rx="3" fill="#bae6fd" />
                      <circle cx="24" cy="23" r="5" fill="#0ea5e9" />
                      <path d="M14 42 C14 36, 34 36, 34 42 Z" fill="#0ea5e9" />
                      <rect x="44" y="18" width="55" height="3.5" rx="1" fill="#0284c7" />
                      <rect x="44" y="27" width="45" height="2.5" rx="1" fill="#38bdf8" />
                      <rect x="44" y="35" width="50" height="2.5" rx="1" fill="#38bdf8" />
                      <path d="M1 8 L1 1 L8 1" fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" />
                      <path d="M112 1 L119 1 L119 8" fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" />
                      <path d="M1 72 L1 79 L8 79" fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" />
                      <path d="M112 79 L119 79 L119 72" fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" />
                    </svg>
                  </div>
                  <div class="text-center">
                    <div class="text-[10px] font-bold text-slate-800">Ảnh hợp lệ</div>
                    <div class="text-[9px] text-emerald-600 font-semibold mt-0.5">Rõ nét, đủ 4 góc</div>
                  </div>
                </div>

                <!-- Mất góc -->
                <div class="bg-white hover:bg-rose-50/5 p-3 rounded-2xl border border-slate-100 hover:border-rose-200/50 shadow-sm flex flex-col justify-between hover:-translate-y-1 hover:shadow-md hover:shadow-rose-500/5 transition-all duration-300 relative overflow-hidden group">
                  <div class="absolute top-2 right-2 w-4 h-4 rounded-full bg-rose-500/10 flex items-center justify-center text-rose-600">
                    <el-icon class="text-[10px]"><Close /></el-icon>
                  </div>
                  <div class="flex justify-center mb-2 mt-1">
                    <svg class="w-full h-14 max-w-[100px] group-hover:scale-105 transition-transform duration-300" viewBox="0 0 120 80">
                      <path d="M 5 15 L 5 75 A 5 5 0 0 0 10 80 L 110 80 A 5 5 0 0 0 115 75 L 115 25 L 95 5 L 10 5 A 5 5 0 0 0 5 15 Z" fill="#f8fafc" stroke="#94a3b8" stroke-width="1" />
                      <path d="M 90 2 L 122 34" fill="none" stroke="#ef4444" stroke-width="1.2" stroke-dasharray="3 2" />
                      <rect x="12" y="15" width="24" height="30" rx="3" fill="#cbd5e1" />
                      <circle cx="24" cy="23" r="5" fill="#94a3b8" />
                      <path d="M14 42 C14 36, 34 36, 34 42 Z" fill="#94a3b8" />
                      <rect x="44" y="18" width="40" height="3" rx="1" fill="#94a3b8" />
                    </svg>
                  </div>
                  <div class="text-center">
                    <div class="text-[10px] font-bold text-slate-800">Ảnh mất góc</div>
                    <div class="text-[9px] text-rose-500 font-semibold mt-0.5">Bị cắt cạnh, thiếu góc</div>
                  </div>
                </div>

                <!-- Lóa sáng -->
                <div class="bg-white hover:bg-rose-50/5 p-3 rounded-2xl border border-slate-100 hover:border-rose-200/50 shadow-sm flex flex-col justify-between hover:-translate-y-1 hover:shadow-md hover:shadow-rose-500/5 transition-all duration-300 relative overflow-hidden group">
                  <div class="absolute top-2 right-2 w-4 h-4 rounded-full bg-rose-500/10 flex items-center justify-center text-rose-600">
                    <el-icon class="text-[10px]"><Close /></el-icon>
                  </div>
                  <div class="flex justify-center mb-2 mt-1">
                    <svg class="w-full h-14 max-w-[100px] group-hover:scale-105 transition-transform duration-300" viewBox="0 0 120 80">
                      <defs>
                        <radialGradient id="glareGrad2" cx="60%" cy="40%" r="35%">
                          <stop offset="0%" stop-color="#ffffff" stop-opacity="1" />
                          <stop offset="60%" stop-color="#ffffff" stop-opacity="0.6" />
                          <stop offset="100%" stop-color="#ffffff" stop-opacity="0" />
                        </radialGradient>
                      </defs>
                      <rect x="5" y="5" width="110" height="70" rx="6" fill="url(#blueCardGrad)" stroke="#0ea5e9" stroke-width="1" />
                      <rect x="12" y="15" width="24" height="30" rx="3" fill="#e0f2fe" />
                      <circle cx="24" cy="23" r="5" fill="#0ea5e9" />
                      <path d="M14 42 C14 36, 34 36, 34 42 Z" fill="#0ea5e9" />
                      <ellipse cx="65" cy="35" rx="30" ry="20" fill="url(#glareGrad2)" />
                    </svg>
                  </div>
                  <div class="text-center">
                    <div class="text-[10px] font-bold text-slate-800">Ảnh lóa sáng</div>
                    <div class="text-[9px] text-rose-500 font-semibold mt-0.5">Chói đèn, lóa flash</div>
                  </div>
                </div>

                <!-- Mờ nhòe -->
                <div class="bg-white hover:bg-rose-50/5 p-3 rounded-2xl border border-slate-100 hover:border-rose-200/50 shadow-sm flex flex-col justify-between hover:-translate-y-1 hover:shadow-md hover:shadow-rose-500/5 transition-all duration-300 relative overflow-hidden group">
                  <div class="absolute top-2 right-2 w-4 h-4 rounded-full bg-rose-500/10 flex items-center justify-center text-rose-600">
                    <el-icon class="text-[10px]"><Close /></el-icon>
                  </div>
                  <div class="flex justify-center mb-2 mt-1">
                    <svg class="w-full h-14 max-w-[100px] group-hover:scale-105 transition-transform duration-300" viewBox="0 0 120 80">
                      <defs>
                        <filter id="blurFilter2">
                          <feGaussianBlur stdDeviation="1.8" />
                        </filter>
                      </defs>
                      <g filter="url(#blurFilter2)">
                        <rect x="5" y="5" width="110" height="70" rx="6" fill="url(#blueCardGrad)" stroke="#0ea5e9" stroke-width="1" />
                        <rect x="12" y="15" width="24" height="30" rx="3" fill="#bae6fd" />
                        <circle cx="24" cy="23" r="5" fill="#38bdf8" />
                      </g>
                    </svg>
                  </div>
                  <div class="text-center">
                    <div class="text-[10px] font-bold text-slate-800">Ảnh mờ nhòe</div>
                    <div class="text-[9px] text-rose-500 font-semibold mt-0.5">Rung tay, out nét</div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Hướng dẫn chụp ảnh selfie -->
            <div class="lg:col-span-6 xl:col-span-4 space-y-4">
              <div class="flex items-center gap-2">
                <div class="w-1.5 h-6 rounded-full bg-blue-600"></div>
                <h4 class="font-bold text-slate-800 text-sm tracking-wide">2. Cách chụp ảnh chân dung</h4>
              </div>
              <div class="grid grid-cols-3 gap-2.5">
                <!-- Hợp lệ -->
                <div class="bg-white hover:bg-emerald-50/5 p-3 rounded-2xl border border-slate-100 hover:border-emerald-200/80 shadow-sm flex flex-col justify-between hover:-translate-y-1 hover:shadow-md hover:shadow-emerald-500/5 transition-all duration-300 relative overflow-hidden group">
                  <div class="absolute top-2 right-2 w-4 h-4 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-600">
                    <el-icon class="text-[10px]"><Check /></el-icon>
                  </div>
                  <div class="flex justify-center mb-2 mt-1">
                    <svg class="w-full h-14 max-w-[70px] group-hover:scale-105 transition-transform duration-300" viewBox="0 0 80 80">
                      <circle cx="40" cy="40" r="35" fill="url(#greenFaceGrad)" stroke="#22c55e" stroke-width="1" />
                      <circle cx="40" cy="33" r="13" fill="#dcfce7" stroke="#16a34a" stroke-width="0.8" />
                      <path d="M28 28 C28 20, 52 20, 52 28 C50 25, 30 25, 28 28 Z" fill="#14532d" />
                      <path d="M22 64 C22 52, 58 52, 58 64" fill="none" stroke="#16a34a" stroke-width="1.5" />
                    </svg>
                  </div>
                  <div class="text-center">
                    <div class="text-[10px] font-bold text-slate-800">Ảnh hợp lệ</div>
                    <div class="text-[9px] text-emerald-600 font-semibold mt-0.5">Rõ mặt, đủ sáng</div>
                  </div>
                </div>

                <!-- Che mặt / Đeo kính -->
                <div class="bg-white hover:bg-rose-50/5 p-3 rounded-2xl border border-slate-100 hover:border-rose-200/50 shadow-sm flex flex-col justify-between hover:-translate-y-1 hover:shadow-md hover:shadow-rose-500/5 transition-all duration-300 relative overflow-hidden group">
                  <div class="absolute top-2 right-2 w-4 h-4 rounded-full bg-rose-500/10 flex items-center justify-center text-rose-600">
                    <el-icon class="text-[10px]"><Close /></el-icon>
                  </div>
                  <div class="flex justify-center mb-2 mt-1">
                    <svg class="w-full h-14 max-w-[70px] group-hover:scale-105 transition-transform duration-300" viewBox="0 0 80 80">
                      <circle cx="40" cy="40" r="35" fill="url(#redFaceGrad)" stroke="#ef4444" stroke-width="1" />
                      <circle cx="40" cy="33" r="13" fill="#fee2e2" stroke="#dc2626" stroke-width="0.8" />
                      <rect x="29" y="30" width="10" height="5" rx="2" fill="none" stroke="#7f1d1d" stroke-width="1.2" />
                      <rect x="41" y="30" width="10" height="5" rx="2" fill="none" stroke="#7f1d1d" stroke-width="1.2" />
                      <line x1="39" y1="32.5" x2="41" y2="32.5" stroke="#7f1d1d" stroke-width="1.2" />
                      <path d="M30 38 C32 45, 48 45, 50 38 Z" fill="#991b1b" opacity="0.8" />
                    </svg>
                  </div>
                  <div class="text-center">
                    <div class="text-[10px] font-bold text-slate-800">Che khuôn mặt</div>
                    <div class="text-[9px] text-rose-500 font-semibold mt-0.5">Kính râm, khẩu trang</div>
                  </div>
                </div>

                <!-- Tối / Đội mũ -->
                <div class="bg-white hover:bg-rose-50/5 p-3 rounded-2xl border border-slate-100 hover:border-rose-200/50 shadow-sm flex flex-col justify-between hover:-translate-y-1 hover:shadow-md hover:shadow-rose-500/5 transition-all duration-300 relative overflow-hidden group">
                  <div class="absolute top-2 right-2 w-4 h-4 rounded-full bg-rose-500/10 flex items-center justify-center text-rose-600">
                    <el-icon class="text-[10px]"><Close /></el-icon>
                  </div>
                  <div class="flex justify-center mb-2 mt-1">
                    <svg class="w-full h-14 max-w-[70px] group-hover:scale-105 transition-transform duration-300" viewBox="0 0 80 80">
                      <circle cx="40" cy="40" r="35" fill="#1e293b" stroke="#ef4444" stroke-width="1" />
                      <circle cx="40" cy="35" r="13" fill="#334155" stroke="#64748b" stroke-width="0.8" />
                      <path d="M22 24 C22 10, 58 10, 58 24 Z" fill="#0f172a" />
                      <ellipse cx="40" cy="24" rx="18" ry="3" fill="#0f172a" />
                    </svg>
                  </div>
                  <div class="text-center">
                    <div class="text-[10px] font-bold text-slate-800">Tối / Đội mũ</div>
                    <div class="text-[9px] text-rose-500 font-semibold mt-0.5">Che trán, thiếu sáng</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Document Type Selector -->
        <div class="flex flex-col sm:flex-row sm:items-center">
          <span class="font-bold text-gray-800 mb-2 sm:mb-0 sm:mr-4">Loại giấy tờ xác minh:</span>
          <el-radio-group v-model="documentType" @change="backImage = null; backImageUrl = ''">
            <el-radio-button label="CCCD" value="CCCD">Căn cước công dân</el-radio-button>
            <el-radio-button label="CMND" value="CMND">Chứng minh nhân dân</el-radio-button>
            <el-radio-button label="PASSPORT" value="PASSPORT">Hộ chiếu (Passport)</el-radio-button>
          </el-radio-group>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- 1. Front ID / Passport -->
          <div>
            <div class="mb-2">
              <span class="font-bold text-gray-800">1. {{ documentType === 'PASSPORT' ? 'Ảnh trang thông tin Hộ chiếu' : 'Ảnh mặt trước CCCD/CMND' }}</span>
              <span class="text-xs text-gray-500 ml-2">(Rõ nét, không lóa sáng, không mất góc) *</span>
            </div>
            <el-upload
              class="avatar-uploader border border-dashed border-gray-300 rounded-lg max-w-sm hover:border-blue-500 transition-colors bg-[#f8fafc]"
              action="#"
              :auto-upload="false"
              :show-file-list="false"
              accept="image/jpeg,image/png,image/jpg"
              @change="(file: any) => handleImageChange(file, 'front')"
            >
              <img v-if="frontImageUrl" :src="frontImageUrl" class="w-full aspect-[8.5/5.4] object-contain p-1" />
              <div v-else class="w-full aspect-[8.5/5.4] flex flex-col items-center justify-center text-gray-400">
                <el-icon class="text-3xl mb-1"><Plus /></el-icon>
                <span class="text-sm">Nhấn để chọn ảnh</span>
              </div>
            </el-upload>
          </div>

          <!-- 2. Back ID (Conditional) -->
          <div v-if="documentType !== 'PASSPORT'">
            <div class="mb-2">
              <span class="font-bold text-gray-800">2. Ảnh mặt sau CCCD/CMND</span>
              <span class="text-xs text-gray-500 ml-2">(Đủ góc cạnh, rõ vân tay và ngày cấp) *</span>
            </div>
            <el-upload
              class="avatar-uploader border border-dashed border-gray-300 rounded-lg max-w-sm hover:border-blue-500 transition-colors bg-[#f8fafc]"
              action="#"
              :auto-upload="false"
              :show-file-list="false"
              accept="image/jpeg,image/png,image/jpg"
              @change="(file: any) => handleImageChange(file, 'back')"
            >
              <img v-if="backImageUrl" :src="backImageUrl" class="w-full aspect-[8.5/5.4] object-contain p-1" />
              <div v-else class="w-full aspect-[8.5/5.4] flex flex-col items-center justify-center text-gray-400">
                <el-icon class="text-3xl mb-1"><Plus /></el-icon>
                <span class="text-sm">Nhấn để chọn ảnh</span>
              </div>
            </el-upload>
          </div>
        </div>

        <!-- 3. Selfie (Auto-Capture with Face Overlay) -->
        <div>
          <div class="mb-2">
            <span class="font-bold text-gray-800">3. Ảnh chân dung (Selfie)</span>
            <span class="text-xs text-gray-500 ml-2">(Tự động chụp khi nhận diện khuôn mặt) *</span>
          </div>
          
          <div class="max-w-md mx-auto aspect-[3/4] sm:aspect-video w-full">
            <!-- Camera with face overlay -->
            <div v-if="cameraActive && !selfieImageUrl" class="selfie-camera-container relative border-2 border-blue-400 rounded-xl overflow-hidden bg-black w-full h-full">
              <video ref="videoRef" autoplay playsinline muted class="w-full h-full object-cover mirror-video"></video>
              
              <!-- Oval face guide overlay -->
              <div class="face-overlay absolute inset-0 pointer-events-none">
                <svg class="w-full h-full" viewBox="0 0 400 380" preserveAspectRatio="xMidYMid slice">
                  <defs>
                    <mask id="faceMask">
                      <rect width="100%" height="100%" fill="white" />
                      <ellipse cx="200" cy="170" rx="95" ry="125" fill="black" />
                    </mask>
                  </defs>
                  <rect width="100%" height="100%" fill="rgba(0,0,0,0.55)" mask="url(#faceMask)" />
                  <ellipse cx="200" cy="170" rx="95" ry="125" fill="none"
                    :stroke="faceGuidance === 'PERFECT' ? '#22C55E' : (faceGuidance !== 'NO_FACE' ? '#FACC15' : '#ffffff')" stroke-width="3" stroke-dasharray="8 4"
                    :class="{ 'animate-pulse-border': faceGuidance === 'PERFECT' }" />
                </svg>
              </div>

              <!-- Status & Countdown -->
              <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent px-4 py-4 text-center">
                <div v-if="countdown > 0" class="text-5xl font-bold text-white animate-bounce">{{ countdown }}</div>
                <div v-else-if="faceGuidance === 'PERFECT'" class="text-green-400 text-sm font-medium">✅ Giữ nguyên vị trí...</div>
                <div v-else-if="faceGuidance === 'TOO_FAR'" class="text-yellow-400 text-sm font-bold bg-black/50 inline-block px-3 py-1 rounded-full">Lại gần màn hình hơn</div>
                <div v-else-if="faceGuidance === 'TOO_CLOSE'" class="text-yellow-400 text-sm font-bold bg-black/50 inline-block px-3 py-1 rounded-full">Lùi ra xa một chút</div>
                <div v-else-if="faceGuidance === 'MOVE_LEFT'" class="text-yellow-400 text-sm font-bold bg-black/50 inline-block px-3 py-1 rounded-full">Di chuyển điện thoại sang trái</div>
                <div v-else-if="faceGuidance === 'MOVE_RIGHT'" class="text-yellow-400 text-sm font-bold bg-black/50 inline-block px-3 py-1 rounded-full">Di chuyển điện thoại sang phải</div>
                <div v-else-if="faceGuidance === 'MOVE_UP'" class="text-yellow-400 text-sm font-bold bg-black/50 inline-block px-3 py-1 rounded-full">Hơi ngẩng mặt lên</div>
                <div v-else-if="faceGuidance === 'MOVE_DOWN'" class="text-yellow-400 text-sm font-bold bg-black/50 inline-block px-3 py-1 rounded-full">Hơi cúi mặt xuống</div>
                <div v-else class="text-white/80 text-sm">📷 Đưa khuôn mặt vào khung hình</div>
                
                <div class="flex justify-center gap-3 mt-2">
                  <el-button v-if="showManualCapture" type="primary" size="small" @click="capturePhoto">📸 Chụp thủ công</el-button>
                  <el-button type="danger" size="small" @click="stopCamera" plain>Hủy</el-button>
                </div>
              </div>
            </div>

            <!-- Captured image preview -->
            <div v-else-if="selfieImageUrl" class="relative border-2 border-green-400 rounded-xl overflow-hidden bg-white w-full h-full">
              <img :src="selfieImageUrl" class="w-full h-full object-contain p-2" />
              <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 to-transparent p-4 flex justify-center">
                <el-button type="warning" @click="retakePhoto">🔄 Chụp lại</el-button>
              </div>
            </div>

            <!-- Start camera selection screen -->
            <div v-else class="border-2 border-dashed border-gray-300 rounded-xl w-full h-full flex flex-col items-center justify-center p-4 bg-[#fafafa]">
              <div class="w-12 h-12 sm:w-16 sm:h-16 rounded-full bg-blue-100 flex items-center justify-center mb-3">
                <el-icon class="text-2xl sm:text-3xl text-blue-500"><Camera /></el-icon>
              </div>
              <span class="text-sm font-bold text-gray-700 mb-3 text-center">Bấm để chụp chân dung (Selfie)</span>
              
              <div class="flex flex-col gap-2 w-full max-w-xs justify-center px-4">
                <el-button type="primary" size="default" class="w-full !rounded-lg" @click="startCamera">
                  <el-icon class="mr-1"><Camera /></el-icon> Quét trực tiếp (AI)
                </el-button>
                <el-button type="info" plain size="default" class="w-full !rounded-lg !ml-0" @click="triggerMobileCamera">
                  <el-icon class="mr-1"><Picture /></el-icon> Chụp/Tải ảnh di động
                </el-button>
              </div>
            </div>
          </div>

          <!-- Hidden canvas for capturing -->
          <canvas ref="canvasRef" class="hidden"></canvas>
          <!-- Hidden input for mobile camera/file capture -->
          <input
            type="file"
            ref="selfieFileInputRef"
            accept="image/*"
            capture="user"
            class="hidden"
            @change="handleSelfieFileChange"
          />
        </div>
      </div>

      <div class="mt-10 pt-6 border-t border-gray-100 flex justify-end">
        <el-button type="primary" size="large" :loading="submitting" @click="submitKyc" :disabled="!isReady">
          Gửi hồ sơ xác minh
        </el-button>
      </div>
    </el-card>

    <!-- Detailed Result Dialog -->
    <el-dialog
      v-model="showResultDialog"
      :title="resultData?.status === 'APPROVED' ? 'Xác thực thành công' : resultData?.status === 'REJECTED' ? 'Xác thực thất bại' : 'Đã gửi hồ sơ'"
      width="500px"
      :close-on-click-modal="false"
      align-center
    >
      <div v-if="resultData" class="space-y-4">
        <!-- Status Icon / Header -->
        <div class="text-center">
          <el-icon v-if="resultData.status === 'APPROVED'" class="text-6xl text-green-500 mb-2"><SuccessFilled /></el-icon>
          <el-icon v-else-if="resultData.status === 'REJECTED'" class="text-6xl text-red-500 mb-2"><CircleCloseFilled /></el-icon>
          <el-icon v-else class="text-6xl text-yellow-500 mb-2"><InfoFilled /></el-icon>
          <h3 class="text-lg font-bold">
            {{ resultData.status === 'APPROVED' ? 'Hồ sơ đã được phê duyệt tự động' : resultData.status === 'REJECTED' ? 'Hồ sơ bị từ chối' : 'Hồ sơ đang chờ phê duyệt' }}
          </h3>
        </div>

        <!-- AI Scores -->
        <div v-if="resultData.scores" class="bg-gray-50 p-4 rounded-lg flex flex-col gap-2">
          <div class="flex justify-between items-center text-sm">
            <span class="text-gray-600">Độ khớp khuôn mặt:</span>
            <span :class="{'text-green-600 font-bold': resultData.scores.faceMatch >= 80, 'text-red-600 font-bold': resultData.scores.faceMatch < 80}">
              {{ resultData.scores.faceMatch }}%
            </span>
          </div>
          <el-progress 
            :percentage="resultData.scores.faceMatch" 
            :color="resultData.scores.faceMatch >= 80 ? '#67c23a' : '#f56c6c'" 
            :show-text="false" 
          />
        </div>

        <!-- Extracted Information -->
        <div v-if="resultData.documentInfo" class="bg-blue-50/50 p-4 rounded-lg text-sm space-y-2 border border-blue-100">
          <h4 class="font-semibold text-blue-800 border-b border-blue-200 pb-1 mb-2">Thông tin trích xuất</h4>
          <div class="grid grid-cols-3 gap-1">
            <span class="text-gray-500 col-span-1">Họ tên:</span>
            <strong class="col-span-2">{{ resultData.documentInfo.name }}</strong>
            <span class="text-gray-500 col-span-1">Số giấy tờ:</span>
            <strong class="col-span-2">{{ resultData.documentInfo.id }}</strong>
            <span class="text-gray-500 col-span-1">Ngày sinh:</span>
            <strong class="col-span-2">{{ resultData.documentInfo.birth_day }}</strong>
          </div>
        </div>

        <!-- Warnings / Errors -->
        <div v-if="resultData.warnings && resultData.warnings.length > 0" class="bg-red-50 p-4 rounded-lg border border-red-100">
          <h4 class="font-semibold text-red-700 flex items-center mb-2">
            <el-icon class="mr-1"><Warning /></el-icon> Lý do từ chối:
          </h4>
          <ul class="list-disc pl-5 text-sm text-red-600 space-y-1">
            <li v-for="(warn, idx) in resultData.warnings" :key="idx">{{ warn }}</li>
          </ul>
        </div>
      </div>
      <template #footer>
        <span class="dialog-footer flex justify-end gap-3">
          <el-button v-if="resultData?.status === 'REJECTED'" @click="closeResultDialog">Thử lại</el-button>
          <el-button type="primary" @click="goToDashboard">
            {{ resultData?.status === 'REJECTED' ? 'Về trang chủ' : 'Tiếp tục' }}
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { ekycApi } from '../../services/api';
import { ElMessage } from 'element-plus';
import { Plus, Camera, SuccessFilled, CircleCloseFilled, InfoFilled, Warning, ArrowUp, ArrowDown, Picture, Checked, Check, Close } from '@element-plus/icons-vue';
import * as faceapi from '@vladmandic/face-api';
import { useAuthStore } from '../../store/auth';
import { useRouter } from 'vue-router';
import videoTutorialUrl from '../../assets/video_tutorial_oval_dark.mp4';

const authStore = useAuthStore();
const router = useRouter();

const ekycStatus = ref('NONE');
const rejectReason = ref('');
const submitting = ref(false);
const latestSubmission = ref<any>(null);

const showGuide = ref(true);
const selfieFileInputRef = ref<HTMLInputElement | null>(null);

const showResultDialog = ref(false);
const resultData = ref<any>(null);

const frontImage = ref<File | null>(null);
const backImage = ref<File | null>(null);
const selfieImage = ref<File | null>(null);

const documentType = ref<'CCCD' | 'CMND' | 'PASSPORT'>('CCCD');

const frontImageUrl = ref('');
const backImageUrl = ref('');
const selfieImageUrl = ref('');

// Camera refs
const videoRef = ref<HTMLVideoElement | null>(null);
const canvasRef = ref<HTMLCanvasElement | null>(null);
const cameraActive = ref(false);
let cameraStream: MediaStream | null = null;

type FaceGuidance = 'NONE' | 'PERFECT' | 'TOO_FAR' | 'TOO_CLOSE' | 'MOVE_LEFT' | 'MOVE_RIGHT' | 'MOVE_UP' | 'MOVE_DOWN' | 'NO_FACE';

// Face detection state
const faceGuidance = ref<FaceGuidance>('NONE');
const countdown = ref(0);
const showManualCapture = ref(false);
let detectionInterval: ReturnType<typeof setInterval> | null = null;
let countdownTimer: ReturnType<typeof setInterval> | null = null;
let stabilizationTimer: ReturnType<typeof setTimeout> | null = null;
let manualFallbackTimeout: ReturnType<typeof setTimeout> | null = null;

const isReady = computed(() => {
  if (documentType.value === 'PASSPORT') {
    return !!(frontImage.value && selfieImage.value);
  }
  return !!(frontImage.value && backImage.value && selfieImage.value);
});

onMounted(async () => {
  await fetchStatus();
});

const fetchStatus = async () => {
  try {
      const res = await ekycApi.getStatus();
      let status = res.data.kycStatus || res.data.status || 'NONE';
      if (status === 'PENDING' && !res.data.latestSubmission) {
        status = 'NONE';
      }
      ekycStatus.value = status;
      if (res.data.latestSubmission) {
      latestSubmission.value = res.data.latestSubmission;
      if (res.data.latestSubmission.reviewNote) {
        rejectReason.value = res.data.latestSubmission.reviewNote;
      }
    }
  } catch (err: any) {
    if (err.response?.status === 404) {
      ekycStatus.value = 'NONE';
    }
  }
};

const parsedOcrData = computed(() => {
  if (!latestSubmission.value?.ocrData) return null;
  try {
    return typeof latestSubmission.value.ocrData === 'string'
      ? JSON.parse(latestSubmission.value.ocrData)
      : latestSubmission.value.ocrData;
  } catch {
    return null;
  }
});

const formatDate = (dateInput: string | Date) => {
  if (!dateInput) return '-';
  const d = new Date(dateInput);
  return `${d.toLocaleDateString('vi-VN')} ${d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}`;
};

const handleImageChange = (file: any, type: 'front' | 'back') => {
  const rawFile = file.raw as File;
  const imageUrl = URL.createObjectURL(rawFile);
  
  if (type === 'front') {
    frontImage.value = rawFile;
    frontImageUrl.value = imageUrl;
  } else if (type === 'back') {
    backImage.value = rawFile;
    backImageUrl.value = imageUrl;
  }
};

// ---- Camera + Face Detection ----
const startCamera = async () => {
  try {
    cameraStream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } },
      audio: false,
    });
    cameraActive.value = true;
    faceGuidance.value = 'NONE';
    countdown.value = 0;
    showManualCapture.value = false;

    setTimeout(() => {
      if (videoRef.value) {
        videoRef.value.srcObject = cameraStream;
        videoRef.value.onloadedmetadata = () => {
          startFaceDetection();
        };
      }
    }, 100);

    // Show manual capture fallback after 10 seconds
    manualFallbackTimeout = setTimeout(() => {
      showManualCapture.value = true;
    }, 10000);

  } catch (err) {
    ElMessage.warning('Không thể truy cập camera trực tiếp. Đang chuyển sang trình chụp/tải ảnh của thiết bị.');
    console.error('Camera error:', err);
    triggerMobileCamera();
  }
};

const startFaceDetection = async () => {
  try {
    // Load TinyFaceDetector model from Web
    await faceapi.nets.tinyFaceDetector.loadFromUri('https://vladmandic.github.io/face-api/model/');
  } catch (err) {
    console.error('Failed to load face-api model:', err);
    showManualCapture.value = true;
    return;
  }

  const detectFrame = async () => {
    if (!videoRef.value || !cameraActive.value || selfieImageUrl.value) {
      clearDetectionInterval();
      return;
    }

    try {
      if (videoRef.value.videoWidth > 0 && videoRef.value.videoHeight > 0) {
        const displaySize = { width: videoRef.value.videoWidth, height: videoRef.value.videoHeight };
        const detection = await faceapi.detectSingleFace(videoRef.value, new faceapi.TinyFaceDetectorOptions({ inputSize: 224, scoreThreshold: 0.5 }));
        
        if (detection) {
          const resized = faceapi.resizeResults(detection, displaySize);
          const guidance = checkFacePosition({ boundingBox: resized.box });
          handleFaceGuidance(guidance);
        } else {
          handleFaceGuidance('NO_FACE');
        }
      }
    } catch {
      handleFaceGuidance('NO_FACE');
    }

    if (cameraActive.value && !selfieImageUrl.value) {
      detectionInterval = setTimeout(detectFrame, 250) as any;
    }
  };

  detectFrame();
};

// Return specific guidance based on face bounding box
const checkFacePosition = (face: any): FaceGuidance => {
  if (!videoRef.value) return 'NO_FACE';

  const vw = videoRef.value.videoWidth;
  const vh = videoRef.value.videoHeight;

  // Face bounding box
  const box = face.boundingBox;
  // Since video is mirrored visually, we mirror the X coordinate
  const faceCenterX = vw - (box.x + box.width / 2);
  const faceCenterY = box.y + box.height / 2;
  const faceWidth = box.width;

  // Oval expected parameters
  const ovalCenterX = vw * 0.5;
  const ovalCenterY = vh * 0.447;
  
  // Face width should be around 25-45% of video width
  const expectedWidthMin = vw * 0.22;
  const expectedWidthMax = vw * 0.45;

  if (faceWidth < expectedWidthMin) return 'TOO_FAR';
  if (faceWidth > expectedWidthMax) return 'TOO_CLOSE';

  // Position tolerance (10-12% of width/height)
  const xTol = vw * 0.12;
  const yTol = vh * 0.12;

  // X axis guidance (mirrored so directions are swapped to feel natural)
  if (faceCenterX < ovalCenterX - xTol) return 'MOVE_RIGHT';
  if (faceCenterX > ovalCenterX + xTol) return 'MOVE_LEFT';
  
  // Y axis guidance
  if (faceCenterY < ovalCenterY - yTol) return 'MOVE_DOWN';
  if (faceCenterY > ovalCenterY + yTol) return 'MOVE_UP';

  return 'PERFECT';
};

const handleFaceGuidance = (guidance: FaceGuidance) => {
  // If we are already counting down, only cancel if face is completely lost or very wrong
  // To avoid small micro-movements resetting the timer, we allow minor deviations during countdown.
  if (countdown.value > 0) {
    if (guidance === 'NO_FACE' || guidance === 'TOO_FAR' || guidance === 'TOO_CLOSE') {
      faceGuidance.value = guidance;
      cancelCaptureSequence();
    }
    // else keep counting down
    return;
  }

  faceGuidance.value = guidance;

  if (guidance === 'PERFECT') {
    if (!stabilizationTimer) {
      // 1.5 second stabilization period before auto-capture countdown starts
      stabilizationTimer = setTimeout(() => {
        startCountdown();
      }, 1500);
    }
  } else {
    cancelCaptureSequence();
  }
};

const cancelCaptureSequence = () => {
  if (stabilizationTimer) {
    clearTimeout(stabilizationTimer);
    stabilizationTimer = null;
  }
  if (countdown.value > 0) {
    countdown.value = 0;
    if (countdownTimer) {
      clearInterval(countdownTimer);
      countdownTimer = null;
    }
  }
};

const startCountdown = () => {
  if (countdownTimer) return;
  countdown.value = 3;
  countdownTimer = setInterval(() => {
    countdown.value--;
    if (countdown.value <= 0) {
      if (countdownTimer) clearInterval(countdownTimer);
      countdownTimer = null;
      capturePhoto();
    }
  }, 1000);
};

const clearDetectionInterval = () => {
  if (detectionInterval) {
    clearInterval(detectionInterval);
    detectionInterval = null;
  }
};

const stopCamera = () => {
  clearDetectionInterval();
  cancelCaptureSequence();
  if (manualFallbackTimeout) { clearTimeout(manualFallbackTimeout); manualFallbackTimeout = null; }
  if (cameraStream) {
    cameraStream.getTracks().forEach(track => track.stop());
    cameraStream = null;
  }
  cameraActive.value = false;
  faceGuidance.value = 'NONE';
  showManualCapture.value = false;
};

const capturePhoto = () => {
  clearDetectionInterval();
  if (!videoRef.value || !canvasRef.value) return;
  
  const video = videoRef.value;
  const canvas = canvasRef.value;
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  
  // Mirror the image
  ctx.translate(canvas.width, 0);
  ctx.scale(-1, 1);
  ctx.drawImage(video, 0, 0);
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  
  canvas.toBlob((blob) => {
    if (blob) {
      const file = new File([blob], `selfie_${Date.now()}.jpg`, { type: 'image/jpeg' });
      selfieImage.value = file;
      selfieImageUrl.value = URL.createObjectURL(blob);
    }
  }, 'image/jpeg', 0.92);
  
  stopCamera();
};

const retakePhoto = () => {
  selfieImage.value = null;
  selfieImageUrl.value = '';
  startCamera();
};

const triggerMobileCamera = () => {
  selfieFileInputRef.value?.click();
};

const handleSelfieFileChange = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files.length > 0) {
    const file = target.files[0];
    if (file) {
      selfieImage.value = file;
      selfieImageUrl.value = URL.createObjectURL(file);
      // Tắt camera trực tiếp nếu đang mở để tránh xung đột tài nguyên
      stopCamera();
    }
  }
};

onBeforeUnmount(() => {
  stopCamera();
});

const submitKyc = async () => {
  if (!isReady.value) {
    if (documentType.value === 'PASSPORT') {
      ElMessage.warning('Vui lòng chọn đủ 2 ảnh (Mặt trước hộ chiếu và chân dung).');
    } else {
      ElMessage.warning('Vui lòng chọn đủ 3 ảnh (Mặt trước, mặt sau và chân dung).');
    }
    return;
  }
  
  submitting.value = true;
  try {
    const formData = new FormData();
    formData.append('front', frontImage.value as File);
    if (documentType.value !== 'PASSPORT') {
      formData.append('back', backImage.value as File);
    }
    formData.append('selfie', selfieImage.value as File);
    
    // Dynamic document type
    formData.append('documentType', documentType.value); 

    const response = await ekycApi.submit(formData);
    
    // API returns detailed object with success, status, documentInfo, scores, warnings
    resultData.value = response.data;
    showResultDialog.value = true;
    
    // Update local UI states based on result so background reflects the new state
    if (resultData.value.status) {
      ekycStatus.value = resultData.value.status;
      if (authStore.user) {
        authStore.user.kycStatus = resultData.value.status; // 'APPROVED' | 'REJECTED' | 'NEEDS_REVIEW'
      }
    }
  } catch (error: any) {
    let errMsg = 'Có lỗi xảy ra khi tải ảnh lên.';
    const resData = error.response?.data;
    
    if (resData) {
      if (Array.isArray(resData.message) && resData.message.length > 0) {
        errMsg = resData.message[0]; // Validation formatting
      } else if (typeof resData.message === 'string') {
        errMsg = resData.message;
      } else if (typeof resData === 'string') {
        errMsg = resData;
      }
    }
    
    ElMessage.error(errMsg);
    console.error('eKYC Submit Error:', error);
  } finally {
    submitting.value = false;
  }
};

const closeResultDialog = () => {
  showResultDialog.value = false;
  if (resultData.value?.status !== 'APPROVED' && resultData.value?.status !== 'NEEDS_REVIEW') {
    // Reset form if rejected to try again
    frontImage.value = null;
    backImage.value = null;
    selfieImage.value = null;
    frontImageUrl.value = '';
    backImageUrl.value = '';
    selfieImageUrl.value = '';
    documentType.value = 'CCCD';
  }
};

const goToDashboard = () => {
  showResultDialog.value = false;
  router.push('/user');
};
</script>

<style scoped>
.avatar-uploader {
  cursor: pointer;
  position: relative;
  overflow: hidden;
  background-color: #fafafa;
}
.mirror-video {
  transform: scaleX(-1);
}
.animate-pulse-border {
  animation: pulse-border 1s ease-in-out infinite;
}
@keyframes pulse-border {
  0%, 100% { stroke-opacity: 1; stroke-width: 3; }
  50% { stroke-opacity: 0.5; stroke-width: 5; }
}
</style>
