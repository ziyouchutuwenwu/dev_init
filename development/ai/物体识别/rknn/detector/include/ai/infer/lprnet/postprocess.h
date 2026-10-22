#ifndef LPRNET_POSTPROCESS_H
#define LPRNET_POSTPROCESS_H

#include <string>
#include <vector>

namespace lprnet {

std::string decode_ctc(const float* logits, const std::vector<std::string>& labels);

} // namespace lprnet

#endif // LPRNET_POSTPROCESS_H
