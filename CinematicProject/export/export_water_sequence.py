"""Export cached Houdini FLIP water to individual GLB files for Godot.

Run from Houdini's Python Shell after placing alongside A2Elements.hipnc:
    exec(open(hou.expandString('$HIP/export_water_sequence.py'), encoding='utf-8').read())

Requires the full 800-frame water cache to be set to Load from Disk.
Does not simulate or alter the original water cache.
"""

import hou
import os
import time

FIRST = 1
LAST = 800
root = hou.expandString('$HIP')
folder = os.path.join(root, '_A2_Cinematic', '01_HoudiniExports', 'water_frames')
os.makedirs(folder, exist_ok=True)

# Accept the water output names used during this project. The original File Cache
# is a fallback; the converted polygon outputs are preferred for glTF.
source_paths = [
    '/obj/WaterSimulation/OUT_RIVER_SEQUENCE',
    '/obj/WaterSimulation/out_river_sequence',
    '/obj/WaterSimulation/out_river_vat',
    '/obj/WaterSimulation/OUT_RIVER_VAT_FIXED',
    '/obj/WaterSimulation/out_river_flip',
    '/obj/WaterSimulation/water_cache',
]
source = next((hou.node(path) for path in source_paths if hou.node(path) is not None), None)
if source is None:
    raise RuntimeError('No cached water output found under /obj/WaterSimulation. The FLIP cache was NOT changed.')

# Make a clean, standalone exporter. The earlier command failed because its
# assumed ROP path did not actually exist.
out = hou.node('/out')
rop = out.node('river_mesh_sequence')
if rop is not None and 'gltf' not in rop.type().name().lower():
    raise RuntimeError('/out/river_mesh_sequence exists but is not a glTF exporter.')
if rop is None:
    types = hou.ropNodeTypeCategory().nodeTypes()
    candidate = next((n for n in ('gltf::2.0', 'gltf') if n in types), None)
    if candidate is None:
        candidate = next((n for n in types if n.split('::')[0] == 'gltf'), None)
    if candidate is None:
        raise RuntimeError('No glTF ROP node type is installed in this Houdini session.')
    rop = out.createNode(candidate, node_name='river_mesh_sequence')


def parameter(label, required=True):
    result = next((p for p in rop.parms() if p.parmTemplate().label() == label), None)
    if required and result is None:
        raise RuntimeError('Cannot find glTF parameter: %s. Export has not started.' % label)
    return result


def set_menu_choice(parm, text):
    if parm is None:
        return
    labels = list(parm.menuLabels())
    tokens = list(parm.menuItems())
    for i, label in enumerate(labels):
        if label.strip().lower() == text.lower():
            try:
                parm.set(tokens[i])
            except (hou.OperationFailed, ValueError, TypeError):
                parm.set(i)
            return
    raise RuntimeError('Missing menu choice %r on %s: %r' % (text, parm.name(), labels))


use_sop = parameter('Use SOP Path')
use_sop.set(1)
parameter('SOP Path').set(source.path())
set_menu_choice(parameter('Valid Frame Range'), 'Render Current Frame')
set_menu_choice(parameter('Export Animations to', required=False), 'None')
create_dirs = parameter('Create Intermediate Directories', required=False)
if create_dirs is not None:
    create_dirs.set(1)
output = parameter('Output File')

print('=== WATER SEQUENCE EXPORT ===', flush=True)
print('Reading cached water from:', source.path(), flush=True)
print('Export ROP:', rop.path(), '(' + rop.type().name() + ')', flush=True)
print('Writing frames %d-%d to: %s' % (FIRST, LAST, folder), flush=True)
start = time.time()

for frame in range(FIRST, LAST + 1):
    filename = os.path.join(folder, 'river_%04d.glb' % frame)
    # Resume interrupted exports without overwriting previously completed files.
    if os.path.isfile(filename) and os.path.getsize(filename) > 20 and open(filename, 'rb').read(4) == b'glTF':
        if frame % 25 == 0:
            print('Already present through frame %d/%d' % (frame, LAST), flush=True)
        continue
    hou.setFrame(frame)
    output.set(filename)
    try:
        rop.render(frame_range=(frame, frame), ignore_inputs=True)
    except Exception as exc:
        raise RuntimeError('Stopped at frame %d. GLB export error: %s' % (frame, exc)) from exc
    if not os.path.isfile(filename) or os.path.getsize(filename) <= 20 or open(filename, 'rb').read(4) != b'glTF':
        raise RuntimeError('Stopped at frame %d: glTF exporter did not create a GLB at %s' % (frame, filename))
    if frame == FIRST or frame % 25 == 0 or frame == LAST:
        print('Exported %d/%d (%.1f minutes elapsed)' % (frame, LAST, (time.time() - start) / 60), flush=True)

files = [name for name in os.listdir(folder) if name.startswith('river_') and name.endswith('.glb')]
print('DONE. Found %d GLB files in %s' % (len(files), folder), flush=True)
