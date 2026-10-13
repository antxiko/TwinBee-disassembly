import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica as mm, musica, coteja_psg as c
ruta, idx = sys.argv[1], int(sys.argv[2])
dir0, n = int(sys.argv[3], 16), int(sys.argv[4])
cfg = musica.CFG; rom = open(os.path.join(mm.RAIZ, cfg['rom']), 'rb').read()
L = open(ruta).read().split('\n')
Ms = []; R = {}; cur = -1
for l in L:
    if l.startswith('M '): Ms.append(l.split()[1])
    elif l.startswith('S '): cur += 1; R[cur] = []
    elif l.startswith('R ') and cur >= 0: R[cur].append(l.split()[2])
z = mm.Cartucho(cfg, rom); z.sp = 0xF000
z.mem[0xE000:0xE000 + len(Ms[idx]) // 2] = bytes.fromhex(Ms[idx])
a, ini, cu, _, _ = c.lee(ruta)[idx]
for r in range(14): z.maq.psg[r] = ini[r]
z.a = a
for k, v in {**cfg.get('regs_pide', {}), **cfg.get('regs_pide_de', {}).get(a, {})}.items(): setattr(z, k, v)
z.corre(cfg['pide'])
for k in range(len(R[idx])):
    mine = bytes(z.mem[0xE010:0xE010 + n]).hex().upper()
    if mine != R[idx][k][:2 * n]:
        print('frame', k)
        for j in range(0, n, 16):
            print(' omsx', R[idx][k][2 * j:2 * j + 32]); print(' mio ', mine[2 * j:2 * j + 32])
        break
    mm.cuadro(z)
