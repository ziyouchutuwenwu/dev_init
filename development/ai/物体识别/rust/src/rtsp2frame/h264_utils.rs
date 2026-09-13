pub struct H264Utils;

impl H264Utils {
    pub fn to_annex_b(input: &[u8]) -> Vec<u8> {
        if input.is_empty() {
            return Vec::new();
        }

        if input.starts_with(&[0, 0, 0, 1]) || input.starts_with(&[0, 0, 1]) {
            return input.to_vec();
        }

        let mut out = Vec::with_capacity(input.len() + 16);
        let mut offset = 0;
        let mut is_valid_avcc = true;

        while offset + 4 <= input.len() {
            let len = u32::from_be_bytes([
                input[offset],
                input[offset + 1],
                input[offset + 2],
                input[offset + 3],
            ]) as usize;
            if len == 0 || offset + 4 + len > input.len() {
                is_valid_avcc = false;
                break;
            }
            out.extend_from_slice(&[0x00, 0x00, 0x00, 0x01]);
            out.extend_from_slice(&input[offset + 4..offset + 4 + len]);
            offset += 4 + len;
        }

        if is_valid_avcc && offset == input.len() && !out.is_empty() {
            return out;
        }

        let mut fallback = Vec::with_capacity(4 + input.len());
        fallback.extend_from_slice(&[0x00, 0x00, 0x00, 0x01]);
        fallback.extend_from_slice(input);
        fallback
    }
}
