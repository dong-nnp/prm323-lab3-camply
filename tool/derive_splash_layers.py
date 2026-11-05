"""Extract original connected artwork without recoloring or resampling.

Run from repository root with Python + Pillow. App/runtime needs neither.
Every nontransparent pixel must belong to exactly one expected component.
"""
from array import array
from collections import deque
from pathlib import Path
from PIL import Image, ImageChops

source = Image.open('assets/evia-logo-lime-transparent(4).png').convert('RGBA')
width, height = source.size
alpha = source.getchannel('A').tobytes()
labels = array('i', [0]) * (width * height)
components = []
for index, value in enumerate(alpha):
    if not value or labels[index]:
        continue
    label = len(components) + 1
    labels[index] = label
    queue = deque([index])
    left, top, right, bottom = width, height, 0, 0
    while queue:
        position = queue.popleft()
        y, x = divmod(position, width)
        left, top = min(left, x), min(top, y)
        right, bottom = max(right, x + 1), max(bottom, y + 1)
        for row in range(max(0, y - 1), min(height, y + 2)):
            for column in range(max(0, x - 1), min(width, x + 2)):
                neighbor = row * width + column
                if alpha[neighbor] and not labels[neighbor]:
                    labels[neighbor] = label
                    queue.append(neighbor)
    components.append((left, top, right, bottom))

expected = {
    (671, 139, 769, 263): 'lime-rays',
    (735, 214, 856, 320): 'lime-rays',
    (149, 231, 787, 761): 'ticket',
    (1222, 179, 1373, 322): 'wordmark-via',
    (1380, 337, 1839, 718): 'wordmark-via',
    (767, 341, 1216, 713): 'wordmark-via',
    (1227, 341, 1362, 713): 'wordmark-via',
}
assert source.size == (1952, 806) and set(components) == set(expected), (
    'Source artwork changed. Inspect its geometry before updating the masks.'
)
groups = {name: set() for name in expected.values()}
for label, box in enumerate(components, 1):
    groups[expected[box]].add(label)
output = Path('assets/splash')
output.mkdir(parents=True, exist_ok=True)
assembled = Image.new('RGBA', source.size)
for name, selected in groups.items():
    mask = Image.frombytes('L', source.size, bytes(
        255 if label in selected else 0 for label in labels
    ))
    layer = Image.new('RGBA', source.size)
    layer.paste(source, (0, 0), mask)
    bounds = layer.getbbox()
    cropped = layer.crop(bounds)
    cropped.save(output / f'evia-{name}.png')
    # Paste (not blend): fractional alpha on edges stays byte-for-byte intact.
    assembled.paste(cropped, bounds[:2], mask.crop(bounds))
    print(name, bounds)
assert ImageChops.difference(source, assembled).getbbox() is None
assert source.tobytes() == assembled.tobytes(), 'RGBA reconstruction mismatch'
print('PASS: reconstructed full logo equals original RGBA pixels exactly.')
