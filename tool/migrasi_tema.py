#!/usr/bin/env python3
"""
Migrasi satu layar dari AppColors (statis) ke context.c (ikut tema).

Dipisah jadi berkas supaya bisa dijalankan ulang per layar dan hasilnya
bisa dibalik lewat git kalau tidak sesuai.

Dua pekerjaan yang tidak bisa dilakukan sed:

1. Pemetaan peran, bukan nama. `AppColors.ink` di app ini berarti "teks
   di atas tombol aksen", jadi tujuannya `onAccent` — bukan `ink`.

2. Mencopot `const`. Begitu warnanya jadi `context.c.x`, nilainya bukan
   konstanta lagi, dan setiap `const Widget(...)` yang memuatnya jadi
   tidak sah. Skrip ini mencari kurung penutup yang cocok untuk tiap
   `const`, lalu mencopotnya hanya kalau isinya benar-benar memuat
   `context.c.`.

Pakai:  python3 tool/migrasi_tema.py lib/screens/home_page.dart
"""
import re
import sys
from pathlib import Path

PETA = {
    "AppColors.bg": "context.c.surface",
    "AppColors.surface": "context.c.raised",
    "AppColors.surfaceBorder": "context.c.line",
    "AppColors.onDark": "context.c.ink",
    "AppColors.onDarkMuted": "context.c.inkSoft",
    "AppColors.brandYellow": "context.c.accent",
    "AppColors.ink": "context.c.onAccent",
    "AppColors.white": "context.c.raised",
    "AppColors.black": "SportagoColors.scrim",
    "AppColors.textMuted": "context.c.inkDim",
    "AppColors.textGray": "context.c.inkSoft",
    "AppColors.textDark": "context.c.ink",
    "AppColors.borderGray": "context.c.line",
    "AppColors.dividerGray": "context.c.line",
    "AppColors.fieldFill": "context.c.sunken",
    "AppColors.fieldBorder": "context.c.lineStrong",
    "AppColors.backgroundColor": "context.c.surface",
    "AppColors.inputBackground": "context.c.raised",
    "AppColors.primaryBlue": "context.c.accent",
    "AppColors.darkBlue": "context.c.accentHover",
    "AppColors.lightBlue": "context.c.accentSoft",
}

# Warna literal yang sudah jelas perannya di app ini.
PETA_LITERAL = {
    "const Color(0xFF222226)": "context.c.hoverSurface",
    "Color(0xFF222226)": "context.c.hoverSurface",
}


def copot_const(kode: str) -> tuple[str, int]:
    """Copot `const` dari tiap ekspresi yang isinya memuat context.c."""
    jumlah = 0
    while True:
        ubah = False
        for m in re.finditer(r"\bconst\s+(?=[A-Z_<\[])", kode):
            mulai = m.end()
            # Cari kurung pembuka pertama sesudah nama konstruktor.
            j = mulai
            while j < len(kode) and kode[j] not in "([{":
                if kode[j] == ";" or kode[j] == "\n" and kode[j - 1] == ";":
                    break
                j += 1
            if j >= len(kode) or kode[j] not in "([{":
                continue
            buka = kode[j]
            tutup = {"(": ")", "[": "]", "{": "}"}[buka]
            dalam = 1
            k = j + 1
            while k < len(kode) and dalam:
                if kode[k] == buka:
                    dalam += 1
                elif kode[k] == tutup:
                    dalam -= 1
                k += 1
            isi = kode[j:k]
            if "context.c." in isi or "SportagoColors." in isi:
                kode = kode[: m.start()] + kode[m.end():]
                jumlah += 1
                ubah = True
                break
        if not ubah:
            return kode, jumlah


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    for arg in sys.argv[1:]:
        p = Path(arg)
        s = p.read_text()
        asli = s

        for a, b in PETA_LITERAL.items():
            s = s.replace(a, b)
        # Nama terpanjang dulu supaya `AppColors.surfaceBorder` tidak
        # terpotong oleh `AppColors.surface`.
        for a in sorted(PETA, key=len, reverse=True):
            s = s.replace(a, PETA[a])

        s, n_const = copot_const(s)

        if "package:flutter/material.dart" in s and "theme/app_tokens.dart" not in s:
            naik = "../" * (len(p.parts) - 2)
            s = re.sub(
                r"(import 'package:flutter/material\.dart';\n)",
                rf"\1import '{naik}theme/app_tokens.dart';\n",
                s,
                count=1,
            )

        if s == asli:
            print(f"  {p}: tidak ada perubahan")
            continue

        p.write_text(s)
        sisa = s.count("AppColors.")
        print(f"  {p}: const dicopot {n_const}, sisa AppColors {sisa}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
