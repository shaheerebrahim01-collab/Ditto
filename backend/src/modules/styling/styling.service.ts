import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import type Anthropic from '@anthropic-ai/sdk';
import { getAnthropicClient, isAnthropicConfigured } from './anthropic-client.provider';
import { RecommendStylingDto } from './dto/recommend-styling.dto';
import { BUTTON_STYLES, FABRIC_IDS, GARMENT_TYPE_IDS, LAPEL_STYLES } from './garment-vocabulary';

// Forces a single structured response rather than free-form prose — the
// enums below are the only values Claude is allowed to return, matching
// GARMENT_TYPE_IDS/FABRIC_IDS/LAPEL_STYLES/BUTTON_STYLES exactly, so a
// recommendation can only ever be something actually orderable through
// the existing Create flow.
const RECOMMENDATION_TOOL: Anthropic.Tool = {
  name: 'recommend_garment',
  description: "Recommend one garment configuration from Ditto's real, orderable options.",
  input_schema: {
    type: 'object',
    properties: {
      garmentTypeId: { type: 'string', enum: [...GARMENT_TYPE_IDS] },
      fabricId: { type: 'string', enum: [...FABRIC_IDS] },
      lapelStyle: { type: 'string', enum: [...LAPEL_STYLES] },
      buttonStyle: { type: 'string', enum: [...BUTTON_STYLES] },
      rationale: {
        type: 'string',
        description: 'One or two plain-language sentences explaining the pick to the customer.',
      },
    },
    required: ['garmentTypeId', 'fabricId', 'lapelStyle', 'buttonStyle', 'rationale'],
  },
};

@Injectable()
export class StylingService {
  private readonly logger = new Logger(StylingService.name);

  // Not wired up to run for real yet — same "structurally present, blocked
  // on a credential" state Firebase was in for part of Phase 3. Throws a
  // clean, catchable error instead of a raw SDK failure so the caller (and
  // anyone testing this endpoint today) gets a clear reason rather than a
  // stack trace about a missing API key.
  async recommend(dto: RecommendStylingDto) {
    if (!isAnthropicConfigured()) {
      throw new ServiceUnavailableException(
        'Styling recommendations are not configured yet — ANTHROPIC_API_KEY is missing. See docs/ROADMAP.md Phase 8.',
      );
    }

    const client = getAnthropicClient();
    let message: Anthropic.Message;
    try {
      message = await client.messages.create({
        model: 'claude-sonnet-5',
        max_tokens: 1024,
        system:
          "You are Ditto's styling consultant. Recommend exactly one garment configuration " +
          'using the recommend_garment tool, choosing only from the enum values provided — ' +
          'never invent a garment type, fabric, lapel style, or button style outside those lists.',
        messages: [
          {
            role: 'user',
            content: [
              `Occasion: ${dto.occasion}`,
              dto.preferences ? `Preferences: ${dto.preferences}` : null,
              dto.budget ? `Budget: $${dto.budget}` : null,
            ]
              .filter((line): line is string => line !== null)
              .join('\n'),
          },
        ],
        tools: [RECOMMENDATION_TOOL],
        tool_choice: { type: 'tool', name: 'recommend_garment' },
      });
    } catch (err) {
      this.logger.error('Anthropic request failed', err instanceof Error ? err.stack : err);
      throw new ServiceUnavailableException('Styling model request failed');
    }

    const toolUse = message.content.find((block) => block.type === 'tool_use');
    if (!toolUse || toolUse.type !== 'tool_use') {
      throw new ServiceUnavailableException('Styling model did not return a recommendation');
    }
    return toolUse.input;
  }
}
