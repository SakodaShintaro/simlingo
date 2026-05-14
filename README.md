# SimLingo

This repository is a fork of <https://github.com/RenzKa/simlingo>.

## セットアップ

### 1. Python 環境構築

```bash
cd ~/work/simlingo
uv venv --python 3.10
source .venv/bin/activate
uv sync
```

### 3. モデルチェックポイント取得

HuggingFace デフォルトキャッシュ (`~/.cache/huggingface/hub/`) に保存:

```bash
huggingface-cli download RenzKa/simlingo
```

実体ファイル確認:

```bash
find ~/.cache/huggingface/hub/models--RenzKa--simlingo -name "*.pt" -not -path "*/blobs/*"
```

## Bench2Drive 評価

CARLA サーバは [Bench2Drive/leaderboard/leaderboard/leaderboard_evaluator.py:209](Bench2Drive/leaderboard/leaderboard/leaderboard_evaluator.py#L209) で自動起動される。手動起動不要。

環境変数とチェックポイント解決は [scripts/_env.sh](scripts/_env.sh) に集約。

### 1 ルート評価 (動作確認用)

```bash
./scripts/eval_1route.sh       # デフォルトは route 00
./scripts/eval_1route.sh 42    # 任意の ID (00..219)
```

オプション環境変数: `PORT` `TM_PORT` `GPU_RANK` `SIMLINGO_CKPT`

結果: `eval_res/<ROUTE_ID>_res.json` / 可視化: `eval_viz/<ROUTE_ID>/`

### 220 ルート評価

```bash
scripts/eval_220routes.sh
```

- `bench2drive_split/*.xml` を順次評価
- 完了済みルート (`eval_res/<ID>_res.json` 存在) は自動スキップ → 中断後の再開可
- ルート失敗時は CARLA をクリーンアップして次へ
- 完走後 `merge_route_json.py` を自動実行

### 追加メトリクス

```bash
python Bench2Drive/tools/ability_benchmark.py -r merge.json
python Bench2Drive/tools/efficiency_smoothness_benchmark.py -f merge.json -m metric_dir/
```

### 可視化 (PNG 保存)

デフォルトでは PNG/動画は保存されない。出すには [team_code/agent_simlingo.py:61](team_code/agent_simlingo.py#L61) の `DEBUG = False` を `True` に変更してから評価実行。`eval_viz/<ID>/<RouteScenario_...>/debug_viz/.../images/<step>.png` に保存される。

注: 上流の [Bench2Drive/tools/generate_video.py](Bench2Drive/tools/generate_video.py) は UniAD/VAD 形式 (`rgb_front/`, `meta/`) を期待しており simlingo 出力には合わない。FFmpeg で直接 mp4 化可能:

```bash
ffmpeg -framerate 20 -i "$IMG_DIR/%d.png" -c:v libx264 -pix_fmt yuv420p out.mp4
```
