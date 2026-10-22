#include "ai/infer/lprnet/postprocess.h"
#include "ai/infer/lprnet/const.h"
#include <algorithm>

namespace lprnet {

std::string decode_ctc(const float* logits, const std::vector<std::string>& labels) {
    if (!logits || labels.size() < LPRNET_OUT_ROWS) {
        return "";
    }

    int prebs[LPRNET_OUT_COLS];
    for (int x = 0; x < LPRNET_OUT_COLS; x++) {
        const float* ptr = logits;
        float preb[LPRNET_OUT_ROWS];
        for (int y = 0; y < LPRNET_OUT_ROWS; y++) {
            preb[y] = ptr[x];
            ptr += LPRNET_OUT_COLS;
        }
        int max_idx = static_cast<int>(std::max_element(preb, preb + LPRNET_OUT_ROWS) - preb);
        prebs[x] = max_idx;
    }

    std::vector<int> collapsed;
    int pre_c = prebs[0];
    if (pre_c != LPRNET_BLANK_INDEX) {
        collapsed.push_back(pre_c);
    }
    for (int i = 1; i < LPRNET_OUT_COLS; ++i) {
        int val = prebs[i];
        if (val == LPRNET_BLANK_INDEX || val == pre_c) {
            pre_c = val;
            continue;
        }
        collapsed.push_back(val);
        pre_c = val;
    }

    std::string result;
    for (int idx : collapsed) {
        if (idx >= 0 && idx < static_cast<int>(labels.size()) && idx != LPRNET_BLANK_INDEX) {
            result += labels[idx];
        }
    }
    return result;
}

} // namespace lprnet
