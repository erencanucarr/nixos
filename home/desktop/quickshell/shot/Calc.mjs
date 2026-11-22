
export function crop(sel, w, h, frameW, frameH) {
    const kx = frameW / w, ky = frameH / h;
    const x1 = Math.round(Math.max(0, sel.x) * kx), x2 = Math.round(Math.min(w, sel.x + sel.width) * kx);
    const y1 = Math.round(Math.max(0, sel.y) * ky), y2 = Math.round(Math.min(h, sel.y + sel.height) * ky);
    return x2 > x1 && y2 > y1 ? { x: x1, y: y1, w: x2 - x1, h: y2 - y1 } : null;
}
