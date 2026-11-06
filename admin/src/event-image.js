const extensions = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
export function validateEventImage(file) {
  if (!extensions[file?.type]) throw new Error('Chọn ảnh JPG, PNG hoặc WebP.');
  if (!file.size || file.size > 5 * 1024 * 1024) throw new Error('Ảnh phải có dung lượng từ 1 byte đến 5 MB.');
  return extensions[file.type];
}
