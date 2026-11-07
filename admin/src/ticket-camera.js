export function directTicketCamera(QrScanner, video, onScan, calculateScanRegion) {
  let stream, engine, timer;
  let stopped = false;
  const canvas = document.createElement('canvas');
  canvas.getContext('2d', { alpha: false, willReadFrequently: true });

  async function scan(capture) {
    if (stopped) return;
    let frame;
    try {
      frame = await capture?.grabFrame();
    } catch {
      // Some camera drivers expose ImageCapture but only support video playback.
      capture = undefined;
    }
    try {
      if (stopped) return;
      const { data } = await QrScanner.scanImage(frame ?? video, {
        qrEngine: engine,
        canvas,
        scanRegion: calculateScanRegion(frame?.width ?? video.videoWidth, frame?.height ?? video.videoHeight),
      });
      if (!stopped) onScan(data);
    } catch {
      // Frames without a readable QR are expected while the camera is active.
    } finally {
      frame?.close();
      if (!stopped) timer = setTimeout(() => { void scan(capture); }, 125);
    }
  }

  return {
    async start() {
      const media = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: { facingMode: { ideal: 'environment' }, width: { ideal: 1280 } },
      });
      if (stopped) {
        media.getTracks().forEach(track => track.stop());
        return;
      }
      stream = media;
      video.srcObject = stream;
      await video.play();
      if (stopped) return;
      const decoder = await QrScanner.createQrEngine();
      if (stopped) {
        if (decoder instanceof Worker) decoder.terminate();
        return;
      }
      engine = decoder;
      void scan(new ImageCapture(stream.getVideoTracks()[0]));
    },
    destroy() {
      stopped = true;
      clearTimeout(timer);
      stream?.getTracks().forEach(track => track.stop());
      video.srcObject = null;
      if (engine instanceof Worker) engine.terminate();
    },
  };
}
